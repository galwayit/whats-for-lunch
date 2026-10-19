/** RevenueCat v2 reads only. Required scopes: subscriptions:read and products:read. */
import { ApiError, ErrorCode } from "./errors.ts";
import type {
  RevenueCatEntitlement,
  RevenueCatPage,
  RevenueCatProduct,
  RevenueCatSnapshot,
  RevenueCatSubscription,
} from "./revenuecat.ts";

const ORIGIN = "https://api.revenuecat.com";
const MAX_PAGES = 10;
type JsonObject = Record<string, unknown>;

function unavailable(): ApiError {
  return new ApiError(
    ErrorCode.UPSTREAM_ERROR,
    "Subscription verification is temporarily unavailable",
  );
}
function object(value: unknown): JsonObject {
  if (!value || typeof value !== "object" || Array.isArray(value)) throw unavailable();
  return value as JsonObject;
}
function text(value: unknown, max = 255): string {
  if (typeof value !== "string" || !value || value.length > max) throw unavailable();
  return value;
}
function timestamp(value: unknown): number | null {
  if (value === null) return null;
  if (typeof value !== "number" || !Number.isSafeInteger(value) || value < 0 || value > 8.64e15) {
    throw unavailable();
  }
  return value;
}
function page<T>(raw: unknown, parse: (item: unknown) => T): RevenueCatPage<T> {
  const body = object(raw);
  if (body.object !== "list" || !Array.isArray(body.items) || body.items.length > 100) {
    throw unavailable();
  }
  if (body.next_page != null) text(body.next_page, 5000);
  return {
    object: "list",
    items: body.items.map(parse),
    next_page: body.next_page as string | null | undefined,
  };
}
function entitlement(raw: unknown): RevenueCatEntitlement {
  const value = object(raw);
  if (value.object !== "entitlement") throw unavailable();
  return {
    object: "entitlement",
    id: text(value.id),
    project_id: text(value.project_id),
    lookup_key: text(value.lookup_key),
    state: text(value.state),
  };
}
function subscription(raw: unknown): RevenueCatSubscription {
  const value = object(raw);
  if (value.object !== "subscription" || typeof value.gives_access !== "boolean") {
    throw unavailable();
  }
  return {
    object: "subscription",
    id: text(value.id),
    customer_id: text(value.customer_id, 1500),
    product_id: value.product_id === null ? null : text(value.product_id),
    current_period_ends_at: timestamp(value.current_period_ends_at),
    ends_at: timestamp(value.ends_at),
    gives_access: value.gives_access,
    status: text(value.status),
    environment: text(value.environment),
    store: text(value.store),
    entitlements: page(value.entitlements, entitlement),
  };
}

export interface RevenueCatConfig {
  projectId: string;
  apiKey: string;
  allowSandbox: boolean;
}

/** A reader is scoped to one reconciliation; product lookups are shared across transferred aliases. */
export function revenueCatReader(config: RevenueCatConfig, fetchImpl: typeof fetch = fetch) {
  if (!/^proj[a-zA-Z0-9_-]{1,251}$/.test(config.projectId) || !config.apiKey.trim()) {
    throw new Error("RevenueCat v2 project ID and secret API key are required");
  }
  const projectPath = `/v2/projects/${encodeURIComponent(config.projectId)}`;
  const signal = AbortSignal.timeout(10_000); // Bound the whole reconciliation, including pagination.
  const products = new Map<string, Promise<RevenueCatProduct>>();

  async function get(path: string, missingCustomer = false): Promise<unknown> {
    try {
      const response = await fetchImpl(`${ORIGIN}${path}`, {
        method: "GET",
        headers: { Authorization: `Bearer ${config.apiKey}`, Accept: "application/json" },
        redirect: "error",
        signal,
      });
      // Authentication, permission, rate-limit and provider failures must not erase paid state.
      if (response.status === 404 && missingCustomer) {
        const error = object(await response.json());
        if (
          error.type === "resource_missing" &&
          (error.param == null || error.param === "customer_id")
        ) {
          return { object: "list", items: [], next_page: null };
        }
        throw unavailable();
      }
      if (!response.ok) {
        await response.body?.cancel();
        throw unavailable();
      }
      return await response.json();
    } catch {
      // Do not propagate provider bodies or transport errors containing credentials/customer data.
      throw unavailable();
    }
  }

  async function allPages<T>(
    path: string,
    parse: (item: unknown) => T,
    options: { initial?: RevenueCatPage<T>; missingCustomer?: boolean; environment?: string } = {},
  ): Promise<T[]> {
    const items: T[] = [];
    const cursors = new Set<string>();
    let cursor: string | undefined;
    for (let index = 0; index < MAX_PAGES; index++) {
      const query = new URLSearchParams({ limit: "100" });
      if (options.environment) query.set("environment", options.environment);
      if (cursor) query.set("starting_after", cursor);
      const current = index === 0 && options.initial
        ? options.initial
        : page(await get(`${path}?${query}`, index === 0 && options.missingCustomer), parse);
      items.push(...current.items);
      if (!current.next_page) return items;
      // Never forward the bearer key to a supplied URL, another project/customer or a redirect.
      let next: URL;
      try {
        next = new URL(current.next_page, ORIGIN);
      } catch {
        throw unavailable();
      }
      if (
        next.origin !== ORIGIN || next.pathname !== path || next.username || next.password ||
        next.hash
      ) {
        throw unavailable();
      }
      cursor = text(next.searchParams.get("starting_after"));
      if (cursors.has(cursor)) throw unavailable();
      cursors.add(cursor);
      // Rebuild the URL ourselves, preserving the selected environment even if next_page omits it.
    }
    throw unavailable(); // An incomplete read must not overwrite a verified entitlement.
  }

  function product(id: string): Promise<RevenueCatProduct> {
    let pending = products.get(id);
    if (!pending) {
      pending = (async () => {
        const value = object(await get(`${projectPath}/products/${encodeURIComponent(id)}`));
        if (value.object !== "product" || value.id !== id) throw unavailable();
        return {
          object: "product" as const,
          id,
          store_identifier: text(value.store_identifier),
          type: text(value.type),
        };
      })();
      products.set(id, pending);
    }
    return pending;
  }

  return async (appUserId: string): Promise<RevenueCatSnapshot> => {
    text(appUserId, 1500);
    const subscriptions = await allPages(
      `${projectPath}/customers/${encodeURIComponent(appUserId)}/subscriptions`,
      subscription,
      { missingCustomer: true, environment: config.allowSandbox ? undefined : "production" },
    );
    const customerProducts: RevenueCatProduct[] = [];
    for (const item of subscriptions) {
      if (
        !item.gives_access || item.store !== "app_store" || !item.product_id ||
        !["production", "sandbox"].includes(item.environment) ||
        (item.environment === "sandbox" && !config.allowSandbox)
      ) continue;
      item.entitlements = {
        object: "list",
        items: await allPages(
          `${projectPath}/subscriptions/${encodeURIComponent(item.id)}/entitlements`,
          entitlement,
          {
            initial: item.entitlements,
          },
        ),
        next_page: null,
      };
      if (
        item.entitlements.items.some((e) =>
          e.lookup_key === "pro" && e.state === "active" && e.project_id === config.projectId
        )
      ) {
        customerProducts.push(await product(item.product_id));
      }
    }
    // The requested customer may be an alias. RevenueCat resolves it; original_customer_id is
    // deliberately never used to grant the old owner access after a transfer.
    return { projectId: config.projectId, subscriptions, products: customerProducts };
  };
}

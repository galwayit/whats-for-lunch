/** Public planning fields and validation. Never include RSVP tokens or user IDs in suggestions. */
import { ApiError, badRequest, ErrorCode } from "./errors.ts";
import { checkSharedText } from "./content-safety.ts";
import {
  optionalNumber,
  optionalString,
  requireEnum,
  requireInteger,
  requireObject,
  requireString,
} from "./validate.ts";
import { fromEpochSeconds, toEpochSeconds } from "./types.ts";

export function planningDetails(body: Record<string, unknown>, fallbackHost: string) {
  if (body.details != null) body = requireObject(body, "details");
  checkSharedText(typeof body.hostName === "string" ? body.hostName : fallbackHost);
  return {
    host_name: (body.hostName == null || body.hostName === "")
      ? fallbackHost.slice(0, 60)
      : requireString(body, "hostName", 60),
    budget_per_person_minor: body.budgetPerPersonMinor == null
      ? null
      : requireInteger(body, "budgetPerPersonMinor", 0, 1_000_000),
    currency_code: body.currencyCode == null ? "AUD" : requireEnum(body, "currencyCode", ["AUD"]),
    payment_arrangement: body.paymentArrangement == null
      ? "undecided"
      : requireEnum(body, "paymentArrangement", [
        "undecided",
        "pay_own",
        "split_equally",
        "host_pays",
      ]),
    payment_method: body.paymentMethod == null ? "undecided" : requireEnum(body, "paymentMethod", [
      "undecided",
      "at_venue",
      "cash",
      "card",
      "bank_transfer",
    ]),
  };
}

export function suggestionInput(body: Record<string, unknown>, now = Date.now() / 1000) {
  if (body.suggestion != null) body = requireObject(body, "suggestion");
  const placeName = optionalString(body, "placeName", 200);
  const placeAddress = optionalString(body, "placeAddress", 400);
  const scheduledAt = optionalNumber(body, "scheduledAt", 0, 4_102_444_800);
  const note = optionalString(body, "note", 500);
  checkSharedText(placeName, placeAddress, note);
  if (!placeName && scheduledAt === null) throw badRequest("Suggest a place or a time");
  if (placeAddress && !placeName) throw badRequest("A place name is required with the address");
  if (scheduledAt !== null && scheduledAt <= now) throw badRequest("Choose a future time");
  return {
    p_place_name: placeName,
    p_place_address: placeAddress,
    p_scheduled_at: scheduledAt === null ? null : fromEpochSeconds(scheduledAt),
    p_note: note,
  };
}

export interface SuggestionRow {
  id: string;
  group_id: string;
  rsvp_id: string;
  display_name: string;
  place_name: string | null;
  place_address: string | null;
  scheduled_at: string | null;
  note: string | null;
  status: string;
  created_at: string;
}
export function suggestionFromRow(row: SuggestionRow) {
  return {
    id: row.id,
    groupId: row.group_id,
    displayName: row.display_name,
    placeName: row.place_name,
    placeAddress: row.place_address,
    scheduledAtEpochSeconds: row.scheduled_at ? toEpochSeconds(row.scheduled_at) : null,
    note: row.note,
    status: row.status,
    createdAtEpochSeconds: toEpochSeconds(row.created_at),
  };
}
export function planningRpcError(error: { code?: string; message: string } | null) {
  if (!error) return;
  if (error.code === "P0002") {
    throw new ApiError(ErrorCode.NOT_FOUND, "This lunch or suggestion is no longer available");
  }
  if (error.code === "42501") throw new ApiError(ErrorCode.FORBIDDEN, "Only the host can do this");
  if (error.code === "22023") throw badRequest(error.message);
  throw new Error(`database: ${error.code ?? "unknown"}`);
}

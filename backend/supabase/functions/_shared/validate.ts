/**
 * @file validate.ts
 * @description Tiny input validators that throw 400 with a field-specific
 *   message. Handlers stay thin by composing these.
 */

import { badRequest } from "./errors.ts";

type Body = Record<string, unknown>;

export function requireNumber(body: Body, field: string, min: number, max: number): number {
  const value = body[field];
  if (typeof value !== "number" || !Number.isFinite(value)) {
    throw badRequest(`${field} must be a number`);
  }
  if (value < min || value > max) throw badRequest(`${field} must be between ${min} and ${max}`);
  return value;
}

export function optionalNumber(body: Body, field: string, min: number, max: number): number | null {
  if (body[field] === undefined || body[field] === null) return null;
  return requireNumber(body, field, min, max);
}

export function requireInteger(body: Body, field: string, min: number, max: number): number {
  const value = requireNumber(body, field, min, max);
  if (!Number.isInteger(value)) throw badRequest(`${field} must be an integer`);
  return value;
}

export function requireString(body: Body, field: string, maxLength: number): string {
  const value = body[field];
  if (typeof value !== "string" || value.trim().length === 0) {
    throw badRequest(`${field} is required`);
  }
  if (value.length > maxLength) throw badRequest(`${field} is longer than ${maxLength} characters`);
  return value.trim();
}

export function optionalString(body: Body, field: string, maxLength: number): string | null {
  if (body[field] === undefined || body[field] === null) return null;
  return requireString(body, field, maxLength);
}

export function requireEnum<T extends string>(body: Body, field: string, allowed: readonly T[]): T {
  const value = body[field];
  if (typeof value !== "string" || !allowed.includes(value as T)) {
    throw badRequest(`${field} must be one of ${allowed.join(", ")}`);
  }
  return value as T;
}

export function requireObject(body: Body, field: string): Record<string, unknown> {
  const value = body[field];
  if (typeof value !== "object" || value === null || Array.isArray(value)) {
    throw badRequest(`${field} must be an object`);
  }
  return value as Record<string, unknown>;
}

export function optionalObject(body: Body, field: string): Record<string, unknown> {
  if (body[field] === undefined || body[field] === null) return {};
  return requireObject(body, field);
}

export function requireArray(body: Body, field: string, maxLength: number): unknown[] {
  const value = body[field];
  if (!Array.isArray(value)) throw badRequest(`${field} must be an array`);
  if (value.length > maxLength) throw badRequest(`${field} may have at most ${maxLength} items`);
  return value;
}

export function stringArray(value: unknown): string[] {
  return Array.isArray(value) ? value.filter((v): v is string => typeof v === "string") : [];
}

const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export function requireUuid(body: Body, field: string): string {
  const value = requireString(body, field, 36);
  if (!UUID_PATTERN.test(value)) throw badRequest(`${field} must be a UUID`);
  return value.toLowerCase();
}

/** Google place ids are opaque; bound the length and character set only. */
export function requirePlaceId(body: Body, field: string): string {
  const value = requireString(body, field, 300);
  if (!/^[A-Za-z0-9_-]+$/.test(value)) throw badRequest(`${field} is malformed`);
  return value;
}

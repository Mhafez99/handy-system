import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function formatCurrency(value: number | null | undefined) {
  const amount = typeof value === "number" ? value : 0;
  return `${amount.toLocaleString("ar-EG")} ج.م`;
}

export function formatNumber(value: number | null | undefined) {
  const amount = typeof value === "number" ? value : 0;
  return amount.toLocaleString("ar-EG");
}

export function formatPercent(rate: number | null | undefined) {
  const value = typeof rate === "number" ? rate : 0;
  return `${(value * 100).toLocaleString("ar-EG", {
    maximumFractionDigits: 2,
  })}%`;
}

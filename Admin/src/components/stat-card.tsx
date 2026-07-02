import type { ReactNode } from "react";

import { Card, CardContent } from "@/components/ui/card";
import { cn } from "@/lib/utils";

type StatCardProps = {
  label: string;
  value: ReactNode;
  hint?: ReactNode;
  icon?: ReactNode;
  accent?: "default" | "success" | "primary" | "destructive";
};

const accentClasses: Record<NonNullable<StatCardProps["accent"]>, string> = {
  default: "bg-muted text-muted-foreground",
  primary: "bg-primary/10 text-primary",
  success: "bg-success/12 text-success",
  destructive: "bg-destructive/12 text-destructive",
};

export function StatCard({
  label,
  value,
  hint,
  icon,
  accent = "default",
}: StatCardProps) {
  return (
    <Card>
      <CardContent className="flex items-start justify-between gap-3 p-5">
        <div className="min-w-0">
          <p className="truncate text-sm font-semibold text-muted-foreground">
            {label}
          </p>
          <p className="mt-1.5 text-2xl font-extrabold tracking-tight">
            {value}
          </p>
          {hint ? (
            <p className="mt-1 text-xs text-muted-foreground">{hint}</p>
          ) : null}
        </div>
        {icon ? (
          <span
            className={cn(
              "flex size-10 shrink-0 items-center justify-center rounded-xl [&_svg]:size-5",
              accentClasses[accent],
            )}
          >
            {icon}
          </span>
        ) : null}
      </CardContent>
    </Card>
  );
}

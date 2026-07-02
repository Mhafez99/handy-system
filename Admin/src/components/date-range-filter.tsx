"use client";

import { useEffect, useMemo, useState } from "react";
import {
  getOverviewDateRange,
  type OverviewDatePreset,
  type OverviewDateRange,
} from "@/lib/admin";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

const datePresets: Array<{ id: OverviewDatePreset; label: string }> = [
  { id: "today", label: "اليوم" },
  { id: "7d", label: "7 أيام" },
  { id: "30d", label: "30 يوم" },
  { id: "all", label: "الكل" },
  { id: "custom", label: "مخصص" },
];

type DateRangeFilterProps = {
  defaultPreset?: OverviewDatePreset;
  onRangeChange: (range: OverviewDateRange) => void;
};

export function DateRangeFilter({
  defaultPreset = "30d",
  onRangeChange,
}: DateRangeFilterProps) {
  const [preset, setPreset] = useState<OverviewDatePreset>(defaultPreset);
  const [customFrom, setCustomFrom] = useState("");
  const [customTo, setCustomTo] = useState("");

  const range = useMemo(
    () => getOverviewDateRange(preset, customFrom, customTo),
    [preset, customFrom, customTo],
  );

  useEffect(() => {
    onRangeChange(range);
  }, [range, onRangeChange]);

  return (
    <div className="flex flex-col gap-3">
      <div className="flex flex-wrap gap-2">
        {datePresets.map((item) => (
          <Button
            key={item.id}
            type="button"
            size="sm"
            variant={preset === item.id ? "default" : "outline"}
            onClick={() => setPreset(item.id)}
          >
            {item.label}
          </Button>
        ))}
      </div>

      {preset === "custom" ? (
        <div className="grid gap-3 sm:grid-cols-2">
          <div className="grid gap-1.5">
            <Label htmlFor="range-from">من</Label>
            <Input
              id="range-from"
              type="date"
              value={customFrom}
              onChange={(event) => setCustomFrom(event.target.value)}
            />
          </div>
          <div className="grid gap-1.5">
            <Label htmlFor="range-to">إلى</Label>
            <Input
              id="range-to"
              type="date"
              value={customTo}
              onChange={(event) => setCustomTo(event.target.value)}
            />
          </div>
        </div>
      ) : null}
    </div>
  );
}

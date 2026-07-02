"use client";

import { useEffect, useState } from "react";
import { Percent, Save } from "lucide-react";
import {
  loadSettings,
  updateCategoryCommission,
  updateSettings,
  type AdminSettings,
  type CategoryCommission,
} from "@/lib/admin";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { formatPercent } from "@/lib/utils";

type SettingsPanelProps = {
  refreshToken: number;
  onMessage: (message: string) => void;
  onError: (error: string) => void;
};

export function SettingsPanel({
  refreshToken,
  onMessage,
  onError,
}: SettingsPanelProps) {
  const [settings, setSettings] = useState<AdminSettings | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [ratePercent, setRatePercent] = useState("");
  const [minOrderPrice, setMinOrderPrice] = useState("");
  const [isSaving, setIsSaving] = useState(false);

  useEffect(() => {
    let cancelled = false;
    setIsLoading(true);
    onError("");

    loadSettings()
      .then((next) => {
        if (cancelled) return;
        setSettings(next);
        setRatePercent((next.default_commission_rate * 100).toString());
        setMinOrderPrice(next.min_order_price.toString());
      })
      .catch((error) => {
        if (!cancelled) {
          onError(error instanceof Error ? error.message : "حدث خطأ غير متوقع.");
        }
      })
      .finally(() => {
        if (!cancelled) setIsLoading(false);
      });

    return () => {
      cancelled = true;
    };
  }, [refreshToken, onError]);

  async function reload() {
    const next = await loadSettings();
    setSettings(next);
  }

  async function saveGlobal(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    onError("");
    onMessage("");

    const rate = Number(ratePercent) / 100;
    const minPrice = Number(minOrderPrice);

    if (Number.isNaN(rate) || rate < 0 || rate > 1) {
      onError("نسبة العمولة يجب أن تكون بين 0 و100%.");
      return;
    }
    if (Number.isNaN(minPrice) || minPrice < 0) {
      onError("الحد الأدنى للطلب غير صحيح.");
      return;
    }

    setIsSaving(true);
    try {
      await updateSettings({
        defaultCommissionRate: rate,
        minOrderPrice: minPrice,
      });
      await reload();
      onMessage("تم حفظ الإعدادات العامة.");
    } catch (error) {
      onError(error instanceof Error ? error.message : "حدث خطأ غير متوقع.");
    } finally {
      setIsSaving(false);
    }
  }

  if (isLoading || !settings) {
    return (
      <div className="grid gap-5">
        <Skeleton className="h-56 rounded-xl" />
        <Skeleton className="h-72 rounded-xl" />
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-5">
      <Card>
        <CardHeader>
          <CardTitle>العمولة العامة</CardTitle>
          <CardDescription>
            النسبة الافتراضية التي تخصمها المنصة من مستحقات الصنايعي عند إتمام
            الطلب. تُطبَّق على الفئات التي ليس لها نسبة مخصّصة.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={saveGlobal} className="grid gap-4 sm:grid-cols-2">
            <div className="grid gap-1.5">
              <Label htmlFor="rate">نسبة العمولة (%)</Label>
              <Input
                id="rate"
                type="number"
                min={0}
                max={100}
                step="0.5"
                value={ratePercent}
                onChange={(event) => setRatePercent(event.target.value)}
                dir="ltr"
              />
            </div>
            <div className="grid gap-1.5">
              <Label htmlFor="min-price">الحد الأدنى للطلب (ج.م)</Label>
              <Input
                id="min-price"
                type="number"
                min={0}
                value={minOrderPrice}
                onChange={(event) => setMinOrderPrice(event.target.value)}
                dir="ltr"
              />
            </div>
            <div className="sm:col-span-2">
              <Button type="submit" disabled={isSaving}>
                <Save />
                {isSaving ? "جاري الحفظ..." : "حفظ الإعدادات"}
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>عمولة كل فئة</CardTitle>
          <CardDescription>
            يمكن تحديد نسبة مخصّصة لكل فئة تتجاوز النسبة العامة، أو تركها فارغة
            لاستخدام النسبة العامة ({formatPercent(settings.default_commission_rate)}
            ).
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>الفئة</TableHead>
                <TableHead>النسبة الحالية</TableHead>
                <TableHead className="w-72">تعديل النسبة (%)</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {settings.categories.map((category) => (
                <CategoryRow
                  key={category.id}
                  category={category}
                  defaultRate={settings.default_commission_rate}
                  onSaved={async (message) => {
                    await reload();
                    onMessage(message);
                  }}
                  onError={onError}
                />
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  );
}

function CategoryRow({
  category,
  defaultRate,
  onSaved,
  onError,
}: {
  category: CategoryCommission;
  defaultRate: number;
  onSaved: (message: string) => Promise<void>;
  onError: (error: string) => void;
}) {
  const [value, setValue] = useState(
    category.commission_rate == null
      ? ""
      : (category.commission_rate * 100).toString(),
  );
  const [isSaving, setIsSaving] = useState(false);

  async function save(rate: number | null) {
    setIsSaving(true);
    onError("");
    try {
      await updateCategoryCommission(category.id, rate);
      await onSaved(
        rate == null
          ? `تم ضبط ${category.name} على النسبة العامة.`
          : `تم تحديث عمولة ${category.name}.`,
      );
    } catch (error) {
      onError(error instanceof Error ? error.message : "حدث خطأ غير متوقع.");
    } finally {
      setIsSaving(false);
    }
  }

  async function handleSave() {
    const trimmed = value.trim();
    if (trimmed === "") {
      await save(null);
      return;
    }

    const rate = Number(trimmed) / 100;
    if (Number.isNaN(rate) || rate < 0 || rate > 1) {
      onError(`نسبة ${category.name} يجب أن تكون بين 0 و100%.`);
      return;
    }
    await save(rate);
  }

  return (
    <TableRow>
      <TableCell className="font-semibold">{category.name}</TableCell>
      <TableCell>
        {category.commission_rate == null ? (
          <Badge variant="secondary">
            عام ({formatPercent(defaultRate)})
          </Badge>
        ) : (
          <Badge>{formatPercent(category.commission_rate)}</Badge>
        )}
      </TableCell>
      <TableCell>
        <div className="flex items-center gap-2">
          <Input
            type="number"
            min={0}
            max={100}
            step="0.5"
            placeholder="عام"
            value={value}
            onChange={(event) => setValue(event.target.value)}
            dir="ltr"
            className="max-w-28"
          />
          <Button
            type="button"
            size="sm"
            variant="outline"
            disabled={isSaving}
            onClick={handleSave}
          >
            <Percent />
            حفظ
          </Button>
        </div>
      </TableCell>
    </TableRow>
  );
}

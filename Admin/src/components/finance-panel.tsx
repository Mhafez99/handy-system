"use client";

import { useCallback, useEffect, useState } from "react";
import {
  Area,
  AreaChart,
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import { Coins, Receipt, TrendingUp, Wallet } from "lucide-react";
import {
  loadRevenueByCategory,
  loadRevenueDaily,
  loadRevenueStats,
  loadWorkerPayouts,
  type OverviewDateRange,
  type RevenueByCategory,
  type RevenueDailyPoint,
  type RevenueStats,
  type WorkerPayout,
} from "@/lib/admin";
import { DateRangeFilter } from "@/components/date-range-filter";
import { StatCard } from "@/components/stat-card";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Skeleton } from "@/components/ui/skeleton";
import { formatCurrency, formatNumber } from "@/lib/utils";

const chartColors = [
  "var(--chart-1)",
  "var(--chart-2)",
  "var(--chart-3)",
  "var(--chart-4)",
  "var(--chart-5)",
];

type FinancePanelProps = {
  refreshToken: number;
  onError: (error: string) => void;
};

export function FinancePanel({ refreshToken, onError }: FinancePanelProps) {
  const [range, setRange] = useState<OverviewDateRange>({
    from: null,
    to: null,
  });
  const [stats, setStats] = useState<RevenueStats | null>(null);
  const [daily, setDaily] = useState<RevenueDailyPoint[]>([]);
  const [byCategory, setByCategory] = useState<RevenueByCategory[]>([]);
  const [payouts, setPayouts] = useState<WorkerPayout[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  const handleRangeChange = useCallback((next: OverviewDateRange) => {
    setRange(next);
  }, []);

  useEffect(() => {
    let cancelled = false;
    setIsLoading(true);
    onError("");

    Promise.all([
      loadRevenueStats(range),
      loadRevenueDaily(range),
      loadRevenueByCategory(range),
      loadWorkerPayouts(range, 20),
    ])
      .then(([nextStats, nextDaily, nextByCategory, nextPayouts]) => {
        if (cancelled) return;
        setStats(nextStats);
        setDaily(nextDaily);
        setByCategory(nextByCategory);
        setPayouts(nextPayouts);
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
  }, [range, refreshToken, onError]);

  const dailyChart = daily.map((point) => ({
    ...point,
    label: formatShortDay(point.day),
  }));

  const pieData = byCategory
    .filter((row) => row.total_commission > 0)
    .map((row) => ({
      name: row.category_name,
      value: row.total_commission,
    }));

  return (
    <div className="flex flex-col gap-5">
      <Card>
        <CardHeader>
          <CardTitle>الفترة الزمنية</CardTitle>
          <CardDescription>
            {stats?.is_filtered
              ? "الأرقام محسوبة على الطلبات المكتملة داخل الفترة المختارة."
              : "عرض شامل لكل الطلبات المكتملة."}
          </CardDescription>
        </CardHeader>
        <CardContent>
          <DateRangeFilter onRangeChange={handleRangeChange} />
        </CardContent>
      </Card>

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        {isLoading || !stats ? (
          Array.from({ length: 4 }).map((_, index) => (
            <Skeleton key={index} className="h-28 rounded-xl" />
          ))
        ) : (
          <>
            <StatCard
              label="عمولة المنصة (الأرباح)"
              value={formatCurrency(stats.total_commission)}
              hint={`من ${formatNumber(stats.completed_count)} طلب مكتمل`}
              icon={<Coins />}
              accent="primary"
            />
            <StatCard
              label="إجمالي قيمة الأعمال"
              value={formatCurrency(stats.total_gross)}
              hint="ما دفعه العملاء"
              icon={<Receipt />}
            />
            <StatCard
              label="صافي مستحقات الصنايعية"
              value={formatCurrency(stats.total_net)}
              hint="بعد خصم العمولة"
              icon={<Wallet />}
              accent="success"
            />
            <StatCard
              label="متوسط قيمة الطلب"
              value={formatCurrency(stats.avg_order)}
              icon={<TrendingUp />}
            />
          </>
        )}
      </div>

      <Card>
        <CardHeader>
          <CardTitle>تطور الإيراد اليومي</CardTitle>
          <CardDescription>
            العمولة مقابل إجمالي قيمة الأعمال يوميًا.
          </CardDescription>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <Skeleton className="h-72 w-full" />
          ) : dailyChart.length === 0 ? (
            <EmptyState />
          ) : (
            <ResponsiveContainer width="100%" height={300}>
              <AreaChart data={dailyChart} margin={{ right: 8, left: 8, top: 8 }}>
                <defs>
                  <linearGradient id="grossFill" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="var(--chart-2)" stopOpacity={0.4} />
                    <stop offset="95%" stopColor="var(--chart-2)" stopOpacity={0} />
                  </linearGradient>
                  <linearGradient id="commissionFill" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="var(--chart-1)" stopOpacity={0.5} />
                    <stop offset="95%" stopColor="var(--chart-1)" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="var(--border)" />
                <XAxis
                  dataKey="label"
                  tick={{ fontSize: 12, fill: "var(--muted-foreground)" }}
                  reversed
                />
                <YAxis
                  tick={{ fontSize: 12, fill: "var(--muted-foreground)" }}
                  width={48}
                  orientation="right"
                />
                <Tooltip content={<ChartTooltip />} />
                <Area
                  type="monotone"
                  dataKey="total_gross"
                  name="إجمالي الأعمال"
                  stroke="var(--chart-2)"
                  fill="url(#grossFill)"
                  strokeWidth={2}
                />
                <Area
                  type="monotone"
                  dataKey="total_commission"
                  name="العمولة"
                  stroke="var(--chart-1)"
                  fill="url(#commissionFill)"
                  strokeWidth={2}
                />
              </AreaChart>
            </ResponsiveContainer>
          )}
        </CardContent>
      </Card>

      <div className="grid gap-5 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>العمولة حسب الفئة</CardTitle>
            <CardDescription>توزيع أرباح المنصة على الفئات.</CardDescription>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <Skeleton className="h-64 w-full" />
            ) : pieData.length === 0 ? (
              <EmptyState />
            ) : (
              <ResponsiveContainer width="100%" height={260}>
                <PieChart>
                  <Pie
                    data={pieData}
                    dataKey="value"
                    nameKey="name"
                    innerRadius={60}
                    outerRadius={100}
                    paddingAngle={2}
                  >
                    {pieData.map((entry, index) => (
                      <Cell
                        key={entry.name}
                        fill={chartColors[index % chartColors.length]}
                      />
                    ))}
                  </Pie>
                  <Tooltip content={<ChartTooltip />} />
                </PieChart>
              </ResponsiveContainer>
            )}
            <div className="mt-3 flex flex-wrap gap-3">
              {pieData.map((entry, index) => (
                <span
                  key={entry.name}
                  className="flex items-center gap-1.5 text-xs text-muted-foreground"
                >
                  <i
                    className="size-3 rounded-full"
                    style={{
                      background: chartColors[index % chartColors.length],
                    }}
                  />
                  {entry.name}
                </span>
              ))}
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>قيمة الأعمال حسب الفئة</CardTitle>
            <CardDescription>إجمالي المبالغ لكل فئة.</CardDescription>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <Skeleton className="h-64 w-full" />
            ) : byCategory.length === 0 ? (
              <EmptyState />
            ) : (
              <ResponsiveContainer width="100%" height={260}>
                <BarChart
                  data={byCategory}
                  layout="vertical"
                  margin={{ left: 8, right: 8 }}
                >
                  <CartesianGrid
                    strokeDasharray="3 3"
                    stroke="var(--border)"
                    horizontal={false}
                  />
                  <XAxis
                    type="number"
                    tick={{ fontSize: 12, fill: "var(--muted-foreground)" }}
                  />
                  <YAxis
                    type="category"
                    dataKey="category_name"
                    width={90}
                    tick={{ fontSize: 12, fill: "var(--muted-foreground)" }}
                  />
                  <Tooltip content={<ChartTooltip />} cursor={{ fill: "var(--muted)" }} />
                  <Bar
                    dataKey="total_gross"
                    name="قيمة الأعمال"
                    fill="var(--chart-2)"
                    radius={[0, 6, 6, 0]}
                  />
                  <Bar
                    dataKey="total_commission"
                    name="العمولة"
                    fill="var(--chart-1)"
                    radius={[0, 6, 6, 0]}
                  />
                </BarChart>
              </ResponsiveContainer>
            )}
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>مستحقات الصنايعية</CardTitle>
          <CardDescription>
            أعلى الصنايعية من حيث الصافي بعد خصم العمولة.
          </CardDescription>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <Skeleton className="h-48 w-full" />
          ) : payouts.length === 0 ? (
            <EmptyState />
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>الصنايعي</TableHead>
                  <TableHead>الأعمال</TableHead>
                  <TableHead>قيمة الأعمال</TableHead>
                  <TableHead>العمولة</TableHead>
                  <TableHead>الصافي المستحق</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {payouts.map((payout) => (
                  <TableRow key={payout.worker_id}>
                    <TableCell>
                      <div className="font-semibold">{payout.worker_name}</div>
                      <div className="text-xs text-muted-foreground" dir="ltr">
                        {payout.worker_phone}
                      </div>
                    </TableCell>
                    <TableCell>{formatNumber(payout.jobs_count)}</TableCell>
                    <TableCell>{formatCurrency(payout.total_gross)}</TableCell>
                    <TableCell className="text-primary">
                      {formatCurrency(payout.total_commission)}
                    </TableCell>
                    <TableCell className="font-bold text-success">
                      {formatCurrency(payout.total_net)}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

function ChartTooltip({
  active,
  payload,
  label,
}: {
  active?: boolean;
  payload?: Array<{ name: string; value: number; color: string }>;
  label?: string;
}) {
  if (!active || !payload || payload.length === 0) {
    return null;
  }

  return (
    <div className="rounded-lg border border-border bg-popover p-3 text-xs shadow-md">
      {label ? <p className="mb-1 font-bold">{label}</p> : null}
      {payload.map((item) => (
        <p key={item.name} className="flex items-center gap-2">
          <i
            className="size-2.5 rounded-full"
            style={{ background: item.color }}
          />
          <span className="text-muted-foreground">{item.name}:</span>
          <span className="font-semibold">{formatCurrency(item.value)}</span>
        </p>
      ))}
    </div>
  );
}

function EmptyState() {
  return (
    <div className="flex h-48 items-center justify-center text-sm text-muted-foreground">
      لا توجد بيانات للفترة المحددة.
    </div>
  );
}

function formatShortDay(day: string) {
  return new Date(`${day}T00:00:00Z`).toLocaleDateString("ar-EG", {
    day: "numeric",
    month: "short",
  });
}

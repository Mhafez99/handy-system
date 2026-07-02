"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import {
  Area,
  AreaChart,
  Bar,
  BarChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import {
  Activity,
  CheckCircle2,
  ClipboardList,
  MessageSquareWarning,
  Users,
} from "lucide-react";
import {
  getRequestStatusLabel,
  loadOverviewDailyTrend,
  loadOverviewStats,
  loadRecentRequests,
  type AdminDailyTrendPoint,
  type AdminOverviewStats,
  type AdminRecentRequest,
  type OverviewDateRange,
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
import { Badge } from "@/components/ui/badge";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Skeleton } from "@/components/ui/skeleton";
import { formatCurrency, formatNumber } from "@/lib/utils";

type OverviewPanelProps = {
  refreshToken: number;
  onError: (error: string) => void;
};

const trackedStatuses = [
  "new",
  "offered",
  "accepted",
  "on_the_way",
  "in_progress",
  "completed",
  "cancelled",
  "complaint",
] as const;

export function OverviewPanel({ refreshToken, onError }: OverviewPanelProps) {
  const [range, setRange] = useState<OverviewDateRange>({
    from: null,
    to: null,
  });
  const [stats, setStats] = useState<AdminOverviewStats | null>(null);
  const [trend, setTrend] = useState<AdminDailyTrendPoint[]>([]);
  const [requests, setRequests] = useState<AdminRecentRequest[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState("all");

  const handleRangeChange = useCallback((next: OverviewDateRange) => {
    setRange(next);
  }, []);

  useEffect(() => {
    let cancelled = false;
    setIsLoading(true);
    onError("");

    Promise.all([
      loadOverviewStats(range),
      loadOverviewDailyTrend(range),
      loadRecentRequests({
        dateRange: range,
        status: statusFilter === "all" ? null : statusFilter,
      }),
    ])
      .then(([nextStats, nextTrend, nextRequests]) => {
        if (cancelled) return;
        setStats(nextStats);
        setTrend(nextTrend);
        setRequests(nextRequests);
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
  }, [range, statusFilter, refreshToken, onError]);

  const trendChart = useMemo(
    () =>
      trend.map((point) => ({
        ...point,
        label: formatShortDay(point.day),
      })),
    [trend],
  );

  const statusChart = useMemo(() => {
    const counts = stats?.status_counts ?? {};
    return trackedStatuses.map((status) => ({
      status,
      label: getRequestStatusLabel(status),
      count: counts[status] ?? 0,
    }));
  }, [stats]);

  const periodLabel = stats?.is_filtered ? "في الفترة" : "الإجمالي";

  return (
    <div className="flex flex-col gap-5">
      <Card>
        <CardHeader>
          <CardTitle>الفترة الزمنية</CardTitle>
          <CardDescription>
            تُطبَّق الفترة على البطاقات والرسم البياني وقائمة الطلبات.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <DateRangeFilter onRangeChange={handleRangeChange} />
        </CardContent>
      </Card>

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        {isLoading || !stats ? (
          Array.from({ length: 8 }).map((_, index) => (
            <Skeleton key={index} className="h-28 rounded-xl" />
          ))
        ) : (
          <>
            <StatCard
              label={`${periodLabel} الطلبات`}
              value={formatNumber(stats.total_requests)}
              icon={<ClipboardList />}
              accent="primary"
            />
            <StatCard
              label="طلبات نشطة"
              value={formatNumber(stats.active_requests)}
              icon={<Activity />}
            />
            <StatCard
              label="طلبات مكتملة"
              value={formatNumber(stats.completed_requests)}
              icon={<CheckCircle2 />}
              accent="success"
            />
            <StatCard
              label="طلبات اليوم"
              value={formatNumber(stats.requests_today)}
              icon={<ClipboardList />}
            />
            <StatCard
              label="شكاوى مفتوحة"
              value={formatNumber(stats.open_complaints)}
              icon={<MessageSquareWarning />}
              accent={stats.open_complaints > 0 ? "destructive" : "default"}
            />
            <StatCard
              label="صنايعية بانتظار الاعتماد"
              value={formatNumber(stats.pending_workers)}
              icon={<Users />}
            />
            <StatCard
              label="العملاء"
              value={formatNumber(stats.total_customers)}
              icon={<Users />}
            />
            <StatCard
              label="صنايعية نشطة"
              value={formatNumber(stats.active_workers)}
              icon={<Users />}
              accent="success"
            />
          </>
        )}
      </div>

      <div className="grid gap-5 lg:grid-cols-5">
        <Card className="lg:col-span-3">
          <CardHeader>
            <CardTitle>اتجاه الطلبات اليومي</CardTitle>
            <CardDescription>إجمالي الطلبات مقابل المكتملة.</CardDescription>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <Skeleton className="h-72 w-full" />
            ) : trendChart.length === 0 ? (
              <EmptyState />
            ) : (
              <ResponsiveContainer width="100%" height={300}>
                <AreaChart data={trendChart} margin={{ right: 8, left: 8, top: 8 }}>
                  <defs>
                    <linearGradient id="totalFill" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="var(--chart-1)" stopOpacity={0.4} />
                      <stop offset="95%" stopColor="var(--chart-1)" stopOpacity={0} />
                    </linearGradient>
                    <linearGradient id="doneFill" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="var(--chart-3)" stopOpacity={0.5} />
                      <stop offset="95%" stopColor="var(--chart-3)" stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" stroke="var(--border)" />
                  <XAxis
                    dataKey="label"
                    tick={{ fontSize: 12, fill: "var(--muted-foreground)" }}
                    reversed
                  />
                  <YAxis
                    allowDecimals={false}
                    tick={{ fontSize: 12, fill: "var(--muted-foreground)" }}
                    width={36}
                    orientation="right"
                  />
                  <Tooltip content={<ChartTooltip />} />
                  <Area
                    type="monotone"
                    dataKey="total"
                    name="إجمالي"
                    stroke="var(--chart-1)"
                    fill="url(#totalFill)"
                    strokeWidth={2}
                  />
                  <Area
                    type="monotone"
                    dataKey="completed"
                    name="مكتمل"
                    stroke="var(--chart-3)"
                    fill="url(#doneFill)"
                    strokeWidth={2}
                  />
                </AreaChart>
              </ResponsiveContainer>
            )}
          </CardContent>
        </Card>

        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle>توزيع الحالات</CardTitle>
            <CardDescription>عدد الطلبات لكل حالة.</CardDescription>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <Skeleton className="h-72 w-full" />
            ) : (
              <ResponsiveContainer width="100%" height={300}>
                <BarChart
                  data={statusChart}
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
                    allowDecimals={false}
                    tick={{ fontSize: 12, fill: "var(--muted-foreground)" }}
                  />
                  <YAxis
                    type="category"
                    dataKey="label"
                    width={70}
                    tick={{ fontSize: 12, fill: "var(--muted-foreground)" }}
                  />
                  <Tooltip content={<ChartTooltip />} cursor={{ fill: "var(--muted)" }} />
                  <Bar
                    dataKey="count"
                    name="الطلبات"
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
        <CardHeader className="flex-row items-center justify-between gap-4 space-y-0">
          <div>
            <CardTitle>أحدث الطلبات</CardTitle>
            <CardDescription>آخر الطلبات مع حالتها.</CardDescription>
          </div>
          <Select value={statusFilter} onValueChange={setStatusFilter}>
            <SelectTrigger className="w-44">
              <SelectValue placeholder="كل الحالات" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">كل الحالات</SelectItem>
              {trackedStatuses.map((status) => (
                <SelectItem key={status} value={status}>
                  {getRequestStatusLabel(status)}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <Skeleton className="h-48 w-full" />
          ) : requests.length === 0 ? (
            <EmptyState />
          ) : (
            <div className="grid gap-3 md:grid-cols-2">
              {requests.map((request) => (
                <div
                  key={request.id}
                  className="rounded-xl border border-border p-4"
                >
                  <div className="flex items-start justify-between gap-3">
                    <div className="min-w-0">
                      <p className="truncate font-bold">{request.service_name}</p>
                      <p className="truncate text-xs text-muted-foreground">
                        {request.category_name} • {request.governorate}،{" "}
                        {request.area}
                      </p>
                    </div>
                    <Badge variant={statusVariant(request.status)}>
                      {getRequestStatusLabel(request.status)}
                    </Badge>
                  </div>
                  <div className="mt-3 grid gap-1 text-xs text-muted-foreground">
                    <p>
                      العميل:{" "}
                      <span className="text-foreground">
                        {request.customer_name}
                      </span>
                    </p>
                    <p>
                      الصنايعي:{" "}
                      <span className="text-foreground">
                        {request.worker_name || "لم يُقبل عرض بعد"}
                      </span>
                    </p>
                    <p>العروض: {formatNumber(request.offer_count)}</p>
                    {request.final_price != null ? (
                      <p>
                        السعر النهائي:{" "}
                        <span className="font-semibold text-foreground">
                          {formatCurrency(request.final_price)}
                        </span>
                      </p>
                    ) : null}
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

function statusVariant(status: string) {
  switch (status) {
    case "completed":
      return "success" as const;
    case "cancelled":
    case "complaint":
      return "destructive" as const;
    case "new":
    case "offered":
      return "secondary" as const;
    default:
      return "default" as const;
  }
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
          <i className="size-2.5 rounded-full" style={{ background: item.color }} />
          <span className="text-muted-foreground">{item.name}:</span>
          <span className="font-semibold">{formatNumber(item.value)}</span>
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

"use client";

import { useEffect, useMemo, useState } from "react";
import {
  getOverviewDateRange,
  getRequestStatusLabel,
  loadOverviewDailyTrend,
  loadOverviewStats,
  loadRecentRequests,
  type AdminDailyTrendPoint,
  type AdminOverviewStats,
  type AdminRecentRequest,
  type OverviewDatePreset,
} from "@/lib/admin";

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

const datePresets: Array<{ id: OverviewDatePreset; label: string }> = [
  { id: "today", label: "اليوم" },
  { id: "7d", label: "7 أيام" },
  { id: "30d", label: "30 يوم" },
  { id: "all", label: "الكل" },
  { id: "custom", label: "مخصص" },
];

export function OverviewPanel({
  refreshToken,
  onError,
}: OverviewPanelProps) {
  const [stats, setStats] = useState<AdminOverviewStats | null>(null);
  const [trend, setTrend] = useState<AdminDailyTrendPoint[]>([]);
  const [requests, setRequests] = useState<AdminRecentRequest[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [datePreset, setDatePreset] = useState<OverviewDatePreset>("30d");
  const [customFrom, setCustomFrom] = useState("");
  const [customTo, setCustomTo] = useState("");
  const [statusFilter, setStatusFilter] = useState("");

  const dateRange = useMemo(
    () => getOverviewDateRange(datePreset, customFrom, customTo),
    [customFrom, customTo, datePreset],
  );

  const statusCards = useMemo(() => {
    const counts = stats?.status_counts ?? {};
    return trackedStatuses.map((status) => ({
      status,
      label: getRequestStatusLabel(status),
      count: counts[status] ?? 0,
    }));
  }, [stats]);

  const maxStatusCount = useMemo(
    () => Math.max(...statusCards.map((item) => item.count), 1),
    [statusCards],
  );

  const maxTrendTotal = useMemo(
    () => Math.max(...trend.map((point) => point.total), 1),
    [trend],
  );

  const trendSummary = useMemo(() => {
    const total = trend.reduce((sum, point) => sum + point.total, 0);
    const completed = trend.reduce((sum, point) => sum + point.completed, 0);
    return { total, completed };
  }, [trend]);

  const periodLabel = stats?.is_filtered ? "في الفترة" : "إجمالي";

  useEffect(() => {
    let cancelled = false;

    setIsLoading(true);
    onError("");

    const filters = {
      dateRange,
      status: statusFilter || null,
    };

    Promise.all([
      loadOverviewStats(dateRange),
      loadOverviewDailyTrend(dateRange),
      loadRecentRequests(filters),
    ])
      .then(([nextStats, nextTrend, nextRequests]) => {
        if (!cancelled) {
          setStats(nextStats);
          setTrend(nextTrend);
          setRequests(nextRequests);
        }
      })
      .catch((caughtError) => {
        if (!cancelled) {
          onError(getErrorMessage(caughtError));
        }
      })
      .finally(() => {
        if (!cancelled) {
          setIsLoading(false);
        }
      });

    return () => {
      cancelled = true;
    };
  }, [dateRange, onError, refreshToken, statusFilter]);

  if (isLoading) {
    return (
      <section className="panel">
        <p className="muted">جاري تحميل لوحة المتابعة...</p>
      </section>
    );
  }

  if (!stats) {
    return (
      <section className="panel empty">
        <h2>تعذر تحميل الإحصائيات</h2>
        <p className="muted">حاول التحديث مرة أخرى.</p>
      </section>
    );
  }

  return (
    <>
      <section className="panel overview-filters">
        <div className="overview-filters-header">
          <div>
            <h2>الفترة الزمنية</h2>
            <p className="muted">
              {stats.is_filtered
                ? "الإحصائيات والطلبات والرسم البياني محدّدة بالفترة المختارة."
                : "عرض شامل لكل الطلبات. الرسم البياني يعرض آخر 30 يومًا."}
            </p>
          </div>
        </div>

        <div className="filter-chip-row">
          {datePresets.map((preset) => (
            <button
              className={
                datePreset === preset.id ? "filter-chip active" : "filter-chip"
              }
              key={preset.id}
              onClick={() => setDatePreset(preset.id)}
              type="button"
            >
              {preset.label}
            </button>
          ))}
        </div>

        {datePreset === "custom" ? (
          <div className="date-range-inputs">
            <label>
              من
              <input
                onChange={(event) => setCustomFrom(event.target.value)}
                type="date"
                value={customFrom}
              />
            </label>
            <label>
              إلى
              <input
                onChange={(event) => setCustomTo(event.target.value)}
                type="date"
                value={customTo}
              />
            </label>
          </div>
        ) : null}
      </section>

      <section className="stats-grid overview-stats-grid">
        <article className="stat-card">
          <span>{periodLabel} الطلبات</span>
          <strong>{stats.total_requests}</strong>
        </article>
        <article className="stat-card">
          <span>طلبات نشطة {stats.is_filtered ? "في الفترة" : ""}</span>
          <strong>{stats.active_requests}</strong>
        </article>
        <article className="stat-card">
          <span>طلبات مكتملة {stats.is_filtered ? "في الفترة" : ""}</span>
          <strong>{stats.completed_requests}</strong>
        </article>
        <article className="stat-card">
          <span>طلبات اليوم</span>
          <strong>{stats.requests_today}</strong>
        </article>
        <article className="stat-card">
          <span>شكاوى مفتوحة</span>
          <strong>{stats.open_complaints}</strong>
        </article>
        <article className="stat-card">
          <span>صنايعية بانتظار الاعتماد</span>
          <strong>{stats.pending_workers}</strong>
        </article>
        <article className="stat-card">
          <span>العملاء</span>
          <strong>{stats.total_customers}</strong>
        </article>
        <article className="stat-card">
          <span>صنايعية نشطة</span>
          <strong>{stats.active_workers}</strong>
        </article>
        <article className="stat-card">
          <span>
            {stats.is_filtered ? "عروض في الفترة" : "إجمالي العروض"}
          </span>
          <strong>
            {stats.is_filtered ? stats.offers_in_period : stats.total_offers}
          </strong>
        </article>
      </section>

      <section className="panel panel-spacer">
        <div className="chart-panel-header">
          <div>
            <h2>اتجاه الطلبات اليومي</h2>
            <p className="muted">
              {trendSummary.total} طلب • {trendSummary.completed} مكتمل
            </p>
          </div>
        </div>

        {trend.length === 0 ? (
          <p className="muted">لا توجد بيانات للفترة المحددة.</p>
        ) : (
          <div className="trend-chart" role="img" aria-label="رسم بياني يومي للطلبات">
            {trend.map((point) => {
              const totalHeight = Math.max(
                (point.total / maxTrendTotal) * 100,
                point.total > 0 ? 8 : 0,
              );
              const completedHeight =
                point.total > 0
                  ? (point.completed / point.total) * totalHeight
                  : 0;

              return (
                <div className="trend-chart-column" key={point.day}>
                  <div className="trend-chart-bars">
                    <div
                      className="trend-chart-bar total"
                      style={{ height: `${totalHeight}%` }}
                      title={`${point.total} طلب`}
                    >
                      <div
                        className="trend-chart-bar completed"
                        style={{ height: `${completedHeight}%` }}
                      />
                    </div>
                  </div>
                  <span className="trend-chart-label">
                    {formatShortDay(point.day)}
                  </span>
                  <span className="trend-chart-value">{point.total}</span>
                </div>
              );
            })}
          </div>
        )}

        <div className="chart-legend">
          <span>
            <i className="legend-swatch total" /> إجمالي الطلبات
          </span>
          <span>
            <i className="legend-swatch completed" /> مكتملة
          </span>
        </div>
      </section>

      <section className="panel panel-spacer">
        <h2>توزيع الطلبات حسب الحالة</h2>
        <div className="status-bar-chart">
          {statusCards.map((item) => (
            <div className="status-bar-row" key={item.status}>
              <span className="status-bar-label">{item.label}</span>
              <div className="status-bar-track">
                <div
                  className="status-bar-fill"
                  style={{
                    width: `${(item.count / maxStatusCount) * 100}%`,
                  }}
                />
              </div>
              <strong className="status-bar-count">{item.count}</strong>
            </div>
          ))}
        </div>
      </section>

      <section className="panel panel-spacer">
        <div className="overview-list-header">
          <h2>أحدث الطلبات</h2>
          <label className="overview-status-filter">
            الحالة
            <select
              onChange={(event) => setStatusFilter(event.target.value)}
              value={statusFilter}
            >
              <option value="">الكل</option>
              {trackedStatuses.map((status) => (
                <option key={status} value={status}>
                  {getRequestStatusLabel(status)}
                </option>
              ))}
            </select>
          </label>
        </div>

        {requests.length === 0 ? (
          <p className="muted">لا توجد طلبات مطابقة للفلاتر الحالية.</p>
        ) : (
          <div className="workers-list overview-requests-list">
            {requests.map((request) => (
              <article className="worker-card" key={request.id}>
                <div className="worker-header">
                  <div>
                    <h3>{request.service_name}</h3>
                    <p className="muted">
                      {request.category_name} • {request.governorate}،{" "}
                      {request.area}
                    </p>
                  </div>
                  <span className="badge">
                    {getRequestStatusLabel(request.status)}
                  </span>
                </div>

                <div className="worker-details">
                  <p>
                    <strong>العميل:</strong> {request.customer_name}
                  </p>
                  <p>
                    <strong>الصنايعي:</strong>{" "}
                    {request.worker_name || "لم يُقبل عرض بعد"}
                  </p>
                  <p>
                    <strong>العروض:</strong> {request.offer_count}
                  </p>
                  {request.final_price != null ? (
                    <p>
                      <strong>السعر النهائي:</strong> {request.final_price} جنيه
                      {request.payment_method === "cash" ? " (كاش)" : ""}
                    </p>
                  ) : null}
                  <p>
                    <strong>تاريخ الإنشاء:</strong>{" "}
                    {new Date(request.created_at).toLocaleString("ar-EG")}
                  </p>
                </div>
              </article>
            ))}
          </div>
        )}
      </section>
    </>
  );
}

function formatShortDay(day: string) {
  return new Date(`${day}T00:00:00Z`).toLocaleDateString("ar-EG", {
    day: "numeric",
    month: "short",
  });
}

function getErrorMessage(error: unknown) {
  return error instanceof Error ? error.message : "حدث خطأ غير متوقع.";
}

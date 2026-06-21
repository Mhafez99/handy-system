"use client";

import { useEffect, useMemo, useState } from "react";
import {
  getComplaintCategoryLabel,
  getComplaintStatusLabel,
  loadComplaints,
  type AdminComplaint,
  type ComplaintStatus,
  updateComplaintStatus,
} from "@/lib/admin";

type ComplaintsPanelProps = {
  refreshToken: number;
  onMessage: (message: string) => void;
  onError: (error: string) => void;
};

type ComplaintActionState = {
  complaintId: string;
  status: ComplaintStatus;
} | null;

const statusActions: Array<{ status: ComplaintStatus; label: string }> = [
  { status: "in_review", label: "قيد المراجعة" },
  { status: "resolved", label: "تم الحل" },
  { status: "dismissed", label: "رفض" },
];

export function ComplaintsPanel({
  refreshToken,
  onMessage,
  onError,
}: ComplaintsPanelProps) {
  const [complaints, setComplaints] = useState<AdminComplaint[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [actionState, setActionState] = useState<ComplaintActionState>(null);

  const openCount = useMemo(
    () =>
      complaints.filter(
        (complaint) =>
          complaint.status === "open" || complaint.status === "in_review",
      ).length,
    [complaints],
  );

  async function reloadComplaints() {
    onError("");
    setIsLoading(true);

    try {
      const nextComplaints = await loadComplaints();
      setComplaints(nextComplaints);
    } catch (caughtError) {
      onError(getErrorMessage(caughtError));
    } finally {
      setIsLoading(false);
    }
  }

  useEffect(() => {
    let cancelled = false;

    loadComplaints()
      .then((nextComplaints) => {
        if (!cancelled) {
          setComplaints(nextComplaints);
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
  }, [refreshToken, onError]);

  async function handleStatusUpdate(
    complaintId: string,
    status: ComplaintStatus,
  ) {
    onError("");
    onMessage("");
    setActionState({ complaintId, status });

    try {
      await updateComplaintStatus(complaintId, status);
      await reloadComplaints();
      onMessage("تم تحديث حالة الشكوى.");
    } catch (caughtError) {
      onError(getErrorMessage(caughtError));
    } finally {
      setActionState(null);
    }
  }

  if (isLoading) {
    return (
      <section className="panel">
        <p className="muted">جاري تحميل الشكاوى...</p>
      </section>
    );
  }

  if (complaints.length === 0) {
    return (
      <section className="panel empty">
        <h2>لا توجد شكاوى</h2>
        <p className="muted">ستظهر هنا شكاوى العملاء عند إرسالها.</p>
      </section>
    );
  }

  return (
    <>
      <section className="stats-grid">
        <article className="stat-card">
          <span>شكاوى مفتوحة</span>
          <strong>{openCount}</strong>
        </article>
        <article className="stat-card">
          <span>إجمالي الشكاوى</span>
          <strong>{complaints.length}</strong>
        </article>
      </section>

      <section className="workers-list">
        {complaints.map((complaint) => {
          const isBusy = actionState?.complaintId === complaint.id;

          return (
            <article className="worker-card" key={complaint.id}>
              <div className="worker-header">
                <div>
                  <h2>{complaint.service_name}</h2>
                  <p className="muted">
                    {complaint.area} •{" "}
                    {new Date(complaint.created_at).toLocaleString("ar-EG")}
                  </p>
                </div>
                <span className="badge">
                  {getComplaintStatusLabel(complaint.status)}
                </span>
              </div>

              <div className="worker-details">
                <p>
                  <strong>السبب:</strong>{" "}
                  {getComplaintCategoryLabel(complaint.category)}
                </p>
                <p>
                  <strong>العميل:</strong> {complaint.customer_name} •{" "}
                  <span dir="ltr">{complaint.customer_phone}</span>
                </p>
                <p>
                  <strong>الصنايعي:</strong> {complaint.worker_name} •{" "}
                  <span dir="ltr">{complaint.worker_phone}</span>
                </p>
                <p>
                  <strong>التفاصيل:</strong> {complaint.description}
                </p>
              </div>

              <div className="card-actions">
                {statusActions.map((action) => (
                  <button
                    key={action.status}
                    className="secondary-button"
                    disabled={isBusy || complaint.status === action.status}
                    onClick={() =>
                      handleStatusUpdate(complaint.id, action.status)
                    }
                  >
                    {isBusy && actionState?.status === action.status
                      ? "جاري الحفظ..."
                      : action.label}
                  </button>
                ))}
              </div>
            </article>
          );
        })}
      </section>
    </>
  );
}

function getErrorMessage(error: unknown) {
  return error instanceof Error ? error.message : "حدث خطأ غير متوقع.";
}

"use client";

import { useEffect, useMemo, useState } from "react";
import {
  loadReviews,
  type AdminReview,
  updateReviewVisibility,
} from "@/lib/admin";

type ReviewsPanelProps = {
  refreshToken: number;
  onMessage: (message: string) => void;
  onError: (error: string) => void;
};

type ReviewActionState = {
  reviewId: string;
  isHidden: boolean;
} | null;

function renderStars(rating: number) {
  return "★".repeat(rating) + "☆".repeat(5 - rating);
}

export function ReviewsPanel({
  refreshToken,
  onMessage,
  onError,
}: ReviewsPanelProps) {
  const [reviews, setReviews] = useState<AdminReview[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [actionState, setActionState] = useState<ReviewActionState>(null);
  const [minRating, setMinRating] = useState("");
  const [showHidden, setShowHidden] = useState(true);

  const hiddenCount = useMemo(
    () => reviews.filter((review) => review.is_hidden).length,
    [reviews],
  );

  const averageRating = useMemo(() => {
    const visible = reviews.filter((review) => !review.is_hidden);
    if (visible.length === 0) {
      return null;
    }
    const total = visible.reduce((sum, review) => sum + review.rating, 0);
    return (total / visible.length).toFixed(1);
  }, [reviews]);

  async function reloadReviews() {
    onError("");
    setIsLoading(true);

    try {
      const nextReviews = await loadReviews({
        minRating: minRating ? Number(minRating) : null,
        includeHidden: showHidden,
        limit: 100,
      });
      setReviews(nextReviews);
    } catch (caughtError) {
      onError(getErrorMessage(caughtError));
    } finally {
      setIsLoading(false);
    }
  }

  useEffect(() => {
    let cancelled = false;

    loadReviews({
      minRating: minRating ? Number(minRating) : null,
      includeHidden: showHidden,
      limit: 100,
    })
      .then((nextReviews) => {
        if (!cancelled) {
          setReviews(nextReviews);
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
  }, [refreshToken, minRating, showHidden]);

  async function handleVisibilityChange(review: AdminReview, isHidden: boolean) {
    onError("");
    setActionState({ reviewId: review.id, isHidden });

    try {
      await updateReviewVisibility(review.id, isHidden);
      onMessage(isHidden ? "تم إخفاء التقييم." : "تم إظهار التقييم.");
      await reloadReviews();
    } catch (caughtError) {
      onError(getErrorMessage(caughtError));
    } finally {
      setActionState(null);
    }
  }

  return (
    <>
      <section className="stats-grid">
        <article className="stat-card">
          <span>إجمالي التقييمات</span>
          <strong>{reviews.length}</strong>
        </article>
        <article className="stat-card">
          <span>متوسط التقييم</span>
          <strong>{averageRating ?? "—"}</strong>
        </article>
        <article className="stat-card">
          <span>تقييمات مخفية</span>
          <strong>{hiddenCount}</strong>
        </article>
      </section>

      <section className="panel panel-spacer">
        <div className="filters-row">
          <label>
            الحد الأدنى للتقييم
            <select
              value={minRating}
              onChange={(event) => setMinRating(event.target.value)}
            >
              <option value="">الكل</option>
              <option value="1">1+</option>
              <option value="2">2+</option>
              <option value="3">3+</option>
              <option value="4">4+</option>
              <option value="5">5</option>
            </select>
          </label>
          <label className="checkbox-inline">
            <input
              type="checkbox"
              checked={showHidden}
              onChange={(event) => setShowHidden(event.target.checked)}
            />
            عرض التقييمات المخفية
          </label>
        </div>
      </section>

      <section className="workers-list">
        {isLoading ? (
          <div className="panel">
            <p className="muted">جاري تحميل التقييمات...</p>
          </div>
        ) : reviews.length === 0 ? (
          <div className="panel empty">
            <h2>لا توجد تقييمات</h2>
            <p className="muted">ستظهر هنا تقييمات العملاء بعد إتمام الطلبات.</p>
          </div>
        ) : (
          reviews.map((review) => {
            const isBusy = actionState?.reviewId === review.id;
            const isHiding =
              isBusy && actionState?.isHidden === true;
            const isShowing =
              isBusy && actionState?.isHidden === false;

            return (
              <article
                className={`worker-card${review.is_hidden ? " muted-card" : ""}`}
                key={review.id}
              >
                <div className="worker-header">
                  <div>
                    <h2>
                      {review.worker_name}
                      {review.is_hidden ? (
                        <span className="badge warning">مخفي</span>
                      ) : null}
                    </h2>
                    <p className="muted">
                      {review.service_name} • {review.area}
                    </p>
                  </div>
                  <span className="badge rating-badge" dir="ltr">
                    {renderStars(review.rating)} ({review.rating}/5)
                  </span>
                </div>

                <div className="worker-details">
                  <p>
                    <strong>الصنايعي:</strong> {review.worker_name} •{" "}
                    <span dir="ltr">{review.worker_phone}</span>
                  </p>
                  <p>
                    <strong>العميل:</strong> {review.customer_name} •{" "}
                    <span dir="ltr">{review.customer_phone}</span>
                  </p>
                  <p>
                    <strong>التعليق:</strong>{" "}
                    {review.comment.trim() || "بدون تعليق"}
                  </p>
                  <p>
                    <strong>التاريخ:</strong>{" "}
                    {new Date(review.created_at).toLocaleString("ar-EG")}
                  </p>
                </div>

                <div className="card-actions">
                  {review.is_hidden ? (
                    <button
                      className="primary-button"
                      disabled={Boolean(actionState)}
                      onClick={() => handleVisibilityChange(review, false)}
                    >
                      {isShowing ? "جاري الإظهار..." : "إظهار التقييم"}
                    </button>
                  ) : (
                    <button
                      className="danger-button"
                      disabled={Boolean(actionState)}
                      onClick={() => handleVisibilityChange(review, true)}
                    >
                      {isHiding ? "جاري الإخفاء..." : "إخفاء التقييم"}
                    </button>
                  )}
                </div>
              </article>
            );
          })
        )}
      </section>
    </>
  );
}

function getErrorMessage(error: unknown) {
  if (error instanceof Error) {
    return error.message;
  }

  return "حدث خطأ غير متوقع.";
}

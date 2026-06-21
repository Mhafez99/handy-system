"use client";

import { useEffect, useMemo, useState } from "react";
import {
  getUserRoleLabel,
  getUserStatusLabel,
  loadUsers,
  updateUserStatus,
  type AdminUser,
  type UserRoleFilter,
  type UserStatusFilter,
} from "@/lib/admin";

type UsersPanelProps = {
  refreshToken: number;
  onMessage: (message: string) => void;
  onError: (error: string) => void;
};

type UserActionState = {
  userId: string;
  type: "suspend" | "activate";
} | null;

const roleFilters: Array<{ id: UserRoleFilter; label: string }> = [
  { id: null, label: "الكل" },
  { id: "customer", label: "عملاء" },
  { id: "worker", label: "صنايعية" },
];

const statusFilters: Array<{ id: UserStatusFilter; label: string }> = [
  { id: null, label: "الكل" },
  { id: "active", label: "نشط" },
  { id: "pending", label: "بانتظار الاعتماد" },
  { id: "suspended", label: "موقوف" },
];

export function UsersPanel({
  refreshToken,
  onMessage,
  onError,
}: UsersPanelProps) {
  const [users, setUsers] = useState<AdminUser[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [roleFilter, setRoleFilter] = useState<UserRoleFilter>(null);
  const [statusFilter, setStatusFilter] = useState<UserStatusFilter>(null);
  const [actionState, setActionState] = useState<UserActionState>(null);

  const counts = useMemo(() => {
    return {
      active: users.filter((user) => user.status === "active").length,
      suspended: users.filter((user) => user.status === "suspended").length,
      pending: users.filter((user) => user.status === "pending").length,
    };
  }, [users]);

  async function reloadUsers() {
    onError("");
    setIsLoading(true);

    try {
      const nextUsers = await loadUsers({
        role: roleFilter,
        status: statusFilter,
      });
      setUsers(nextUsers);
    } catch (caughtError) {
      onError(getErrorMessage(caughtError));
    } finally {
      setIsLoading(false);
    }
  }

  useEffect(() => {
    let cancelled = false;

    setIsLoading(true);
    onError("");

    loadUsers({ role: roleFilter, status: statusFilter })
      .then((nextUsers) => {
        if (!cancelled) {
          setUsers(nextUsers);
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
  }, [onError, refreshToken, roleFilter, statusFilter]);

  async function handleStatusChange(
    user: AdminUser,
    type: "suspend" | "activate",
  ) {
    onError("");
    onMessage("");
    setActionState({ userId: user.user_id, type });

    try {
      await updateUserStatus(
        user.user_id,
        type === "suspend" ? "suspended" : "active",
      );
      onMessage(
        type === "suspend"
          ? `تم إيقاف حساب ${user.full_name}.`
          : `تم تفعيل حساب ${user.full_name}.`,
      );
      await reloadUsers();
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
          <span>المستخدمون المعروضون</span>
          <strong>{isLoading ? "..." : users.length}</strong>
        </article>
        <article className="stat-card">
          <span>نشط</span>
          <strong>{isLoading ? "..." : counts.active}</strong>
        </article>
        <article className="stat-card">
          <span>موقوف</span>
          <strong>{isLoading ? "..." : counts.suspended}</strong>
        </article>
        <article className="stat-card">
          <span>بانتظار الاعتماد</span>
          <strong>{isLoading ? "..." : counts.pending}</strong>
        </article>
      </section>

      <section className="panel">
        <h2>تصفية المستخدمين</h2>
        <p className="muted">
          إيقاف الحساب يمنع المستخدم من إنشاء الطلبات أو رؤية الطلبات والعروض.
        </p>

        <div className="filter-group">
          <span className="filter-group-label">الدور</span>
          <div className="filter-chip-row">
            {roleFilters.map((filter) => (
              <button
                className={
                  roleFilter === filter.id ? "filter-chip active" : "filter-chip"
                }
                key={filter.label}
                onClick={() => setRoleFilter(filter.id)}
                type="button"
              >
                {filter.label}
              </button>
            ))}
          </div>
        </div>

        <div className="filter-group">
          <span className="filter-group-label">الحالة</span>
          <div className="filter-chip-row">
            {statusFilters.map((filter) => (
              <button
                className={
                  statusFilter === filter.id
                    ? "filter-chip active"
                    : "filter-chip"
                }
                key={filter.label}
                onClick={() => setStatusFilter(filter.id)}
                type="button"
              >
                {filter.label}
              </button>
            ))}
          </div>
        </div>
      </section>

      <section className="workers-list panel-spacer">
        {isLoading ? (
          <div className="panel">
            <p className="muted">جاري تحميل المستخدمين...</p>
          </div>
        ) : users.length === 0 ? (
          <div className="panel empty">
            <h2>لا يوجد مستخدمون مطابقون</h2>
            <p className="muted">جرّب تغيير الفلاتر.</p>
          </div>
        ) : (
          users.map((user) => {
            const isSuspending =
              actionState?.userId === user.user_id &&
              actionState.type === "suspend";
            const isActivating =
              actionState?.userId === user.user_id &&
              actionState.type === "activate";
            const isBusy = Boolean(actionState);
            const canActivate =
              user.status !== "active" &&
              (user.role === "customer" || user.approval_status === "approved");

            return (
              <article className="worker-card" key={user.user_id}>
                <div className="worker-header">
                  <div>
                    <h2>{user.full_name}</h2>
                    <p className="muted">
                      {getUserRoleLabel(user.role)}
                      {user.profession ? ` • ${user.profession}` : ""} •{" "}
                      {user.area}، {user.governorate}
                    </p>
                  </div>
                  <span className="badge">{getUserStatusLabel(user.status)}</span>
                </div>

                <div className="worker-details">
                  <p>
                    <strong>الموبايل:</strong>{" "}
                    <span dir="ltr">{user.phone}</span>
                  </p>
                  {user.role === "worker" ? (
                    <p>
                      <strong>حالة الاعتماد:</strong>{" "}
                      {user.approval_status || "غير محدد"}
                    </p>
                  ) : null}
                  <p>
                    <strong>تاريخ التسجيل:</strong>{" "}
                    {new Date(user.created_at).toLocaleDateString("ar-EG")}
                  </p>
                </div>

                <div className="card-actions">
                  {user.status === "active" ? (
                    <button
                      className="danger-button"
                      disabled={isBusy}
                      onClick={() => handleStatusChange(user, "suspend")}
                      type="button"
                    >
                      {isSuspending ? "جاري الإيقاف..." : "إيقاف الحساب"}
                    </button>
                  ) : canActivate ? (
                    <button
                      className="primary-button"
                      disabled={isBusy}
                      onClick={() => handleStatusChange(user, "activate")}
                      type="button"
                    >
                      {isActivating ? "جاري التفعيل..." : "تفعيل الحساب"}
                    </button>
                  ) : (
                    <p className="muted">
                      لا يمكن تفعيل صنايعي غير معتمد من هنا. راجع تبويب
                      الصنايعية.
                    </p>
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
    if (error.message === "Admin access required") {
      return "ليس لديك صلاحية إدارية.";
    }

    if (error.message === "Worker must be approved before activation") {
      return "لا يمكن تفعيل صنايعي غير معتمد.";
    }

    if (error.message === "Cannot change your own status") {
      return "لا يمكنك تغيير حالة حسابك.";
    }

    if (error.message === "Cannot change admin account status") {
      return "لا يمكن تغيير حالة حساب إداري.";
    }

    return error.message;
  }

  return "حدث خطأ غير متوقع.";
}

"use client";

import { useEffect, useMemo, useState } from "react";
import type { Session } from "@supabase/supabase-js";
import { OverviewPanel } from "@/components/overview-panel";
import { AreasPanel } from "@/components/areas-panel";
import { ComplaintsPanel } from "@/components/complaints-panel";
import { ReviewsPanel } from "@/components/reviews-panel";
import { ServicesPanel } from "@/components/services-panel";
import { UsersPanel } from "@/components/users-panel";
import {
  approveWorker,
  loadPendingWorkers,
  type PendingWorker,
  rejectWorker,
} from "@/lib/admin";
import { isSupabaseConfigured, supabase } from "@/lib/supabase";

type ActionState = {
  workerId: string;
  type: "approve" | "reject";
} | null;

type AdminTab =
  | "overview"
  | "workers"
  | "users"
  | "services"
  | "areas"
  | "complaints"
  | "reviews";

export function AdminDashboard() {
  const [session, setSession] = useState<Session | null>(null);
  const [activeTab, setActiveTab] = useState<AdminTab>("overview");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [workers, setWorkers] = useState<PendingWorker[]>([]);
  const [isLoadingSession, setIsLoadingSession] = useState(true);
  const [isSigningIn, setIsSigningIn] = useState(false);
  const [isLoadingWorkers, setIsLoadingWorkers] = useState(false);
  const [actionState, setActionState] = useState<ActionState>(null);
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");
  const [overviewRefreshToken, setOverviewRefreshToken] = useState(0);
  const [usersRefreshToken, setUsersRefreshToken] = useState(0);
  const [servicesRefreshToken, setServicesRefreshToken] = useState(0);
  const [areasRefreshToken, setAreasRefreshToken] = useState(0);
  const [complaintsRefreshToken, setComplaintsRefreshToken] = useState(0);
  const [reviewsRefreshToken, setReviewsRefreshToken] = useState(0);

  const tabTitle = useMemo(() => {
    switch (activeTab) {
      case "overview":
        return "لوحة المتابعة";
      case "workers":
        return "اعتماد الصنايعية";
      case "users":
        return "إدارة المستخدمين";
      case "services":
        return "إدارة الخدمات";
      case "areas":
        return "إدارة المناطق";
      case "complaints":
        return "مراجعة الشكاوى";
      case "reviews":
        return "تقييمات الصنايعية";
    }
  }, [activeTab]);

  const adminEmail = useMemo(() => session?.user.email ?? "", [session]);

  useEffect(() => {
    supabase.auth.getSession().then(({ data }) => {
      setSession(data.session);
      setIsLoadingSession(false);
    });

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, nextSession) => {
      setSession(nextSession);
      if (!nextSession) {
        setWorkers([]);
      }
    });

    return () => subscription.unsubscribe();
  }, []);

  useEffect(() => {
    if (session) {
      refreshWorkers();
    }
  }, [session]);

  async function signIn(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError("");
    setMessage("");
    setIsSigningIn(true);

    try {
      const { error: signInError } = await supabase.auth.signInWithPassword({
        email,
        password,
      });

      if (signInError) {
        throw new Error(signInError.message);
      }

      setPassword("");
      setMessage("تم تسجيل الدخول بنجاح.");
    } catch (caughtError) {
      setError(getErrorMessage(caughtError));
    } finally {
      setIsSigningIn(false);
    }
  }

  async function signOut() {
    setError("");
    setMessage("");
    await supabase.auth.signOut();
  }

  async function refreshWorkers() {
    setError("");
    setIsLoadingWorkers(true);

    try {
      const nextWorkers = await loadPendingWorkers();
      setWorkers(nextWorkers);
    } catch (caughtError) {
      setError(getErrorMessage(caughtError));
    } finally {
      setIsLoadingWorkers(false);
    }
  }

  async function handleWorkerAction(
    workerId: string,
    type: "approve" | "reject",
  ) {
    setError("");
    setMessage("");
    setActionState({ workerId, type });

    try {
      if (type === "approve") {
        await approveWorker(workerId);
        setMessage("تم اعتماد الصنايعي.");
      } else {
        await rejectWorker(workerId);
        setMessage("تم رفض الصنايعي.");
      }

      await refreshWorkers();
    } catch (caughtError) {
      setError(getErrorMessage(caughtError));
    } finally {
      setActionState(null);
    }
  }

  if (!isSupabaseConfigured) {
    return (
      <main className="shell">
        <section className="panel narrow">
          <p className="eyebrow">Handy Admin</p>
          <h1>إعداد Supabase ناقص</h1>
          <p className="muted">
            أضف `NEXT_PUBLIC_SUPABASE_URL` و
            `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` في ملف `.env.local`.
          </p>
        </section>
      </main>
    );
  }

  if (isLoadingSession) {
    return (
      <main className="shell">
        <section className="panel narrow">
          <p className="muted">جاري تحميل الجلسة...</p>
        </section>
      </main>
    );
  }

  if (!session) {
    return (
      <main className="shell">
        <section className="panel narrow">
          <p className="eyebrow">Handy Admin</p>
          <h1>تسجيل دخول الإدارة</h1>
          <p className="muted">
            استخدم حساب الإدارة المسجل في جدول `admin_users`.
          </p>

          <form className="form" onSubmit={signIn}>
            <label>
              البريد الإلكتروني
              <input
                dir="ltr"
                type="email"
                value={email}
                onChange={(event) => setEmail(event.target.value)}
                placeholder="admin@example.com"
                required
              />
            </label>
            <label>
              كلمة المرور
              <input
                dir="ltr"
                type="password"
                value={password}
                onChange={(event) => setPassword(event.target.value)}
                required
              />
            </label>
            <button className="primary-button" disabled={isSigningIn}>
              {isSigningIn ? "جاري الدخول..." : "دخول"}
            </button>
          </form>

          <Feedback message={message} error={error} />
        </section>
      </main>
    );
  }

  return (
    <main className="shell">
      <header className="topbar">
        <div>
          <p className="eyebrow">Handy Admin</p>
          <h1>{tabTitle}</h1>
          <p className="muted">مسجل كـ {adminEmail}</p>
        </div>
        <div className="topbar-actions">
          {activeTab === "overview" ? (
            <button
              className="secondary-button"
              onClick={() => setOverviewRefreshToken((current) => current + 1)}
            >
              تحديث
            </button>
          ) : activeTab === "workers" ? (
            <button className="secondary-button" onClick={refreshWorkers}>
              تحديث
            </button>
          ) : activeTab === "users" ? (
            <button
              className="secondary-button"
              onClick={() => setUsersRefreshToken((current) => current + 1)}
            >
              تحديث
            </button>
          ) : activeTab === "services" ? (
            <button
              className="secondary-button"
              onClick={() => setServicesRefreshToken((current) => current + 1)}
            >
              تحديث
            </button>
          ) : activeTab === "areas" ? (
            <button
              className="secondary-button"
              onClick={() => setAreasRefreshToken((current) => current + 1)}
            >
              تحديث
            </button>
          ) : activeTab === "reviews" ? (
            <button
              className="secondary-button"
              onClick={() => setReviewsRefreshToken((current) => current + 1)}
            >
              تحديث
            </button>
          ) : (
            <button
              className="secondary-button"
              onClick={() => setComplaintsRefreshToken((current) => current + 1)}
            >
              تحديث
            </button>
          )}
          <button className="ghost-button" onClick={signOut}>
            خروج
          </button>
        </div>
      </header>

      <nav className="admin-tabs" aria-label="أقسام لوحة الإدارة">
        <button
          className={
            activeTab === "overview" ? "tab-button active" : "tab-button"
          }
          onClick={() => {
            setActiveTab("overview");
            setMessage("");
            setError("");
          }}
        >
          المتابعة
        </button>
        <button
          className={activeTab === "workers" ? "tab-button active" : "tab-button"}
          onClick={() => {
            setActiveTab("workers");
            setMessage("");
            setError("");
          }}
        >
          الصنايعية
        </button>
        <button
          className={activeTab === "users" ? "tab-button active" : "tab-button"}
          onClick={() => {
            setActiveTab("users");
            setMessage("");
            setError("");
          }}
        >
          المستخدمون
        </button>
        <button
          className={
            activeTab === "services" ? "tab-button active" : "tab-button"
          }
          onClick={() => {
            setActiveTab("services");
            setMessage("");
            setError("");
          }}
        >
          الخدمات
        </button>
        <button
          className={activeTab === "areas" ? "tab-button active" : "tab-button"}
          onClick={() => {
            setActiveTab("areas");
            setMessage("");
            setError("");
          }}
        >
          المناطق
        </button>
        <button
          className={
            activeTab === "complaints" ? "tab-button active" : "tab-button"
          }
          onClick={() => {
            setActiveTab("complaints");
            setMessage("");
            setError("");
          }}
        >
          الشكاوى
        </button>
        <button
          className={
            activeTab === "reviews" ? "tab-button active" : "tab-button"
          }
          onClick={() => {
            setActiveTab("reviews");
            setMessage("");
            setError("");
          }}
        >
          التقييمات
        </button>
      </nav>

      <Feedback message={message} error={error} />

      {activeTab === "overview" ? (
        <OverviewPanel
          refreshToken={overviewRefreshToken}
          onError={setError}
        />
      ) : activeTab === "workers" ? (
        <>
          <section className="stats-grid">
            <article className="stat-card">
              <span>بانتظار المراجعة</span>
              <strong>{workers.length}</strong>
            </article>
            <article className="stat-card">
              <span>الحالة</span>
              <strong>{isLoadingWorkers ? "تحميل" : "جاهز"}</strong>
            </article>
          </section>

          <section className="workers-list">
            {isLoadingWorkers ? (
              <div className="panel">
                <p className="muted">جاري تحميل الصنايعية...</p>
              </div>
            ) : workers.length === 0 ? (
              <div className="panel empty">
                <h2>لا توجد حسابات معلّقة</h2>
                <p className="muted">أي صنايعي جديد سيظهر هنا للمراجعة.</p>
              </div>
            ) : (
              workers.map((worker) => (
                <WorkerCard
                  key={worker.user_id}
                  worker={worker}
                  actionState={actionState}
                  onApprove={() => handleWorkerAction(worker.user_id, "approve")}
                  onReject={() => handleWorkerAction(worker.user_id, "reject")}
                />
              ))
            )}
          </section>
        </>
      ) : activeTab === "users" ? (
        <UsersPanel
          refreshToken={usersRefreshToken}
          onMessage={setMessage}
          onError={setError}
        />
      ) : activeTab === "services" ? (
        <ServicesPanel
          refreshToken={servicesRefreshToken}
          onMessage={setMessage}
          onError={setError}
        />
      ) : activeTab === "areas" ? (
        <AreasPanel
          key={areasRefreshToken}
          onMessage={setMessage}
          onError={setError}
        />
      ) : activeTab === "reviews" ? (
        <ReviewsPanel
          refreshToken={reviewsRefreshToken}
          onMessage={setMessage}
          onError={setError}
        />
      ) : (
        <ComplaintsPanel
          refreshToken={complaintsRefreshToken}
          onMessage={setMessage}
          onError={setError}
        />
      )}
    </main>
  );
}

function WorkerCard({
  worker,
  actionState,
  onApprove,
  onReject,
}: {
  worker: PendingWorker;
  actionState: ActionState;
  onApprove: () => void;
  onReject: () => void;
}) {
  const isApproving =
    actionState?.workerId === worker.user_id && actionState.type === "approve";
  const isRejecting =
    actionState?.workerId === worker.user_id && actionState.type === "reject";
  const isBusy = Boolean(actionState);

  return (
    <article className="worker-card">
      <div className="worker-header">
        <div>
          <h2>{worker.full_name}</h2>
          <p className="muted">
            {worker.profession} • {worker.area}، {worker.governorate}
          </p>
        </div>
        <span className="badge">{worker.years_experience} سنة خبرة</span>
      </div>

      <div className="worker-details">
        <p>
          <strong>الموبايل:</strong> <span dir="ltr">{worker.phone}</span>
        </p>
        <p>
          <strong>العنوان:</strong> {worker.address}
        </p>
        <p>
          <strong>نبذة:</strong> {worker.bio}
        </p>
        <p>
          <strong>تاريخ التسجيل:</strong>{" "}
          {new Date(worker.created_at).toLocaleDateString("ar-EG")}
        </p>
      </div>

      <div className="card-actions">
        <button
          className="primary-button"
          disabled={isBusy}
          onClick={onApprove}
        >
          {isApproving ? "جاري الاعتماد..." : "اعتماد"}
        </button>
        <button className="danger-button" disabled={isBusy} onClick={onReject}>
          {isRejecting ? "جاري الرفض..." : "رفض"}
        </button>
      </div>
    </article>
  );
}

function Feedback({ message, error }: { message: string; error: string }) {
  if (!message && !error) {
    return null;
  }

  return (
    <div className={error ? "feedback error" : "feedback success"}>
      {error || message}
    </div>
  );
}

function getErrorMessage(error: unknown) {
  if (error instanceof Error) {
    if (error.message === "Admin access required") {
      return "ليس لديك صلاحية إدارية.";
    }

    return error.message;
  }

  return "حدث خطأ غير متوقع.";
}

"use client";

import { useEffect, useMemo, useState } from "react";
import type { Session } from "@supabase/supabase-js";
import {
  LayoutDashboard,
  LogOut,
  MapPin,
  MessageSquareWarning,
  RefreshCw,
  Settings,
  Star,
  UserCheck,
  Users,
  Wallet,
  Wrench,
} from "lucide-react";
import { OverviewPanel } from "@/components/overview-panel";
import { FinancePanel } from "@/components/finance-panel";
import { SettingsPanel } from "@/components/settings-panel";
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
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { cn } from "@/lib/utils";

type ActionState = {
  workerId: string;
  type: "approve" | "reject";
} | null;

type AdminTab =
  | "overview"
  | "finance"
  | "settings"
  | "workers"
  | "users"
  | "services"
  | "areas"
  | "complaints"
  | "reviews";

type NavItem = {
  id: AdminTab;
  label: string;
  title: string;
  icon: React.ComponentType<{ className?: string }>;
};

const navItems: NavItem[] = [
  { id: "overview", label: "المتابعة", title: "لوحة المتابعة", icon: LayoutDashboard },
  { id: "finance", label: "الإيرادات", title: "الإيرادات والعمولات", icon: Wallet },
  { id: "workers", label: "الصنايعية", title: "اعتماد الصنايعية", icon: UserCheck },
  { id: "users", label: "المستخدمون", title: "إدارة المستخدمين", icon: Users },
  { id: "services", label: "الخدمات", title: "إدارة الخدمات", icon: Wrench },
  { id: "areas", label: "المناطق", title: "إدارة المناطق", icon: MapPin },
  { id: "complaints", label: "الشكاوى", title: "مراجعة الشكاوى", icon: MessageSquareWarning },
  { id: "reviews", label: "التقييمات", title: "تقييمات الصنايعية", icon: Star },
  { id: "settings", label: "الإعدادات", title: "إعدادات المنصة", icon: Settings },
];

const legacyTabs: AdminTab[] = [
  "workers",
  "users",
  "services",
  "areas",
  "complaints",
  "reviews",
];

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
  const [refreshTokens, setRefreshTokens] = useState<Record<AdminTab, number>>({
    overview: 0,
    finance: 0,
    settings: 0,
    workers: 0,
    users: 0,
    services: 0,
    areas: 0,
    complaints: 0,
    reviews: 0,
  });

  const activeNav = useMemo(
    () => navItems.find((item) => item.id === activeTab) ?? navItems[0],
    [activeTab],
  );

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

  function bumpRefresh(tab: AdminTab) {
    setRefreshTokens((current) => ({ ...current, [tab]: current[tab] + 1 }));
  }

  function selectTab(tab: AdminTab) {
    setActiveTab(tab);
    setMessage("");
    setError("");
  }

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
      setWorkers(await loadPendingWorkers());
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

  function handleRefresh() {
    if (activeTab === "workers") {
      refreshWorkers();
    } else {
      bumpRefresh(activeTab);
    }
  }

  if (!isSupabaseConfigured) {
    return (
      <CenteredCard
        title="إعداد Supabase ناقص"
        description="أضف NEXT_PUBLIC_SUPABASE_URL و NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY في ملف .env.local."
      />
    );
  }

  if (isLoadingSession) {
    return <CenteredCard title="جاري تحميل الجلسة..." />;
  }

  if (!session) {
    return (
      <main className="mx-auto flex min-h-screen w-full max-w-md items-center px-4">
        <Card className="w-full">
          <CardHeader>
            <p className="text-xs font-extrabold uppercase tracking-widest text-primary">
              Handy Admin
            </p>
            <CardTitle className="text-2xl">تسجيل دخول الإدارة</CardTitle>
            <CardDescription>
              استخدم حساب الإدارة المسجل في جدول admin_users.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <form className="grid gap-4" onSubmit={signIn}>
              <div className="grid gap-1.5">
                <Label htmlFor="email">البريد الإلكتروني</Label>
                <Input
                  id="email"
                  dir="ltr"
                  type="email"
                  value={email}
                  onChange={(event) => setEmail(event.target.value)}
                  placeholder="admin@example.com"
                  required
                />
              </div>
              <div className="grid gap-1.5">
                <Label htmlFor="password">كلمة المرور</Label>
                <Input
                  id="password"
                  dir="ltr"
                  type="password"
                  value={password}
                  onChange={(event) => setPassword(event.target.value)}
                  required
                />
              </div>
              <Button type="submit" disabled={isSigningIn}>
                {isSigningIn ? "جاري الدخول..." : "دخول"}
              </Button>
              <Feedback message={message} error={error} />
            </form>
          </CardContent>
        </Card>
      </main>
    );
  }

  return (
    <div className="flex min-h-screen w-full">
      <aside className="sticky top-0 hidden h-screen w-64 shrink-0 flex-col border-e border-sidebar-border bg-sidebar p-4 lg:flex">
        <div className="flex items-center gap-2 px-2 py-3">
          <span className="flex size-9 items-center justify-center rounded-xl bg-primary text-primary-foreground">
            <LayoutDashboard className="size-5" />
          </span>
          <div>
            <p className="text-sm font-extrabold">Handy Admin</p>
            <p className="text-xs text-muted-foreground">لوحة الإدارة</p>
          </div>
        </div>
        <nav className="mt-4 flex flex-col gap-1">
          {navItems.map((item) => {
            const Icon = item.icon;
            const isActive = item.id === activeTab;
            return (
              <button
                key={item.id}
                onClick={() => selectTab(item.id)}
                className={cn(
                  "flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-semibold transition-colors",
                  isActive
                    ? "bg-primary text-primary-foreground shadow-sm"
                    : "text-sidebar-foreground hover:bg-sidebar-accent",
                )}
              >
                <Icon className="size-4" />
                {item.label}
              </button>
            );
          })}
        </nav>
      </aside>

      <div className="flex min-w-0 flex-1 flex-col">
        <header className="sticky top-0 z-10 flex flex-wrap items-center justify-between gap-3 border-b border-border bg-background/80 px-4 py-4 backdrop-blur md:px-8">
          <div>
            <h1 className="text-xl font-extrabold md:text-2xl">
              {activeNav.title}
            </h1>
            <p className="text-xs text-muted-foreground">مسجل كـ {adminEmail}</p>
          </div>
          <div className="flex items-center gap-2">
            <Button variant="outline" size="sm" onClick={handleRefresh}>
              <RefreshCw />
              تحديث
            </Button>
            <Button variant="ghost" size="sm" onClick={signOut}>
              <LogOut />
              خروج
            </Button>
          </div>
        </header>

        <nav className="flex gap-1 overflow-x-auto border-b border-border px-4 py-2 lg:hidden">
          {navItems.map((item) => (
            <button
              key={item.id}
              onClick={() => selectTab(item.id)}
              className={cn(
                "whitespace-nowrap rounded-full px-3 py-1.5 text-sm font-semibold",
                item.id === activeTab
                  ? "bg-primary text-primary-foreground"
                  : "text-muted-foreground hover:bg-accent",
              )}
            >
              {item.label}
            </button>
          ))}
        </nav>

        <main className="mx-auto w-full max-w-6xl flex-1 px-4 py-6 md:px-8">
          <Feedback message={message} error={error} />

          <div className={cn(legacyTabs.includes(activeTab) && "legacy")}>
            {activeTab === "overview" ? (
              <OverviewPanel
                refreshToken={refreshTokens.overview}
                onError={setError}
              />
            ) : activeTab === "finance" ? (
              <FinancePanel
                refreshToken={refreshTokens.finance}
                onError={setError}
              />
            ) : activeTab === "settings" ? (
              <SettingsPanel
                refreshToken={refreshTokens.settings}
                onMessage={setMessage}
                onError={setError}
              />
            ) : activeTab === "workers" ? (
              <WorkersView
                workers={workers}
                isLoading={isLoadingWorkers}
                actionState={actionState}
                onApprove={(id) => handleWorkerAction(id, "approve")}
                onReject={(id) => handleWorkerAction(id, "reject")}
              />
            ) : activeTab === "users" ? (
              <UsersPanel
                refreshToken={refreshTokens.users}
                onMessage={setMessage}
                onError={setError}
              />
            ) : activeTab === "services" ? (
              <ServicesPanel
                refreshToken={refreshTokens.services}
                onMessage={setMessage}
                onError={setError}
              />
            ) : activeTab === "areas" ? (
              <AreasPanel
                key={refreshTokens.areas}
                onMessage={setMessage}
                onError={setError}
              />
            ) : activeTab === "reviews" ? (
              <ReviewsPanel
                refreshToken={refreshTokens.reviews}
                onMessage={setMessage}
                onError={setError}
              />
            ) : (
              <ComplaintsPanel
                refreshToken={refreshTokens.complaints}
                onMessage={setMessage}
                onError={setError}
              />
            )}
          </div>
        </main>
      </div>
    </div>
  );
}

function WorkersView({
  workers,
  isLoading,
  actionState,
  onApprove,
  onReject,
}: {
  workers: PendingWorker[];
  isLoading: boolean;
  actionState: ActionState;
  onApprove: (id: string) => void;
  onReject: (id: string) => void;
}) {
  return (
    <div className="flex flex-col gap-4">
      <div className="grid gap-4 sm:grid-cols-2">
        <Card>
          <CardContent className="p-5">
            <p className="text-sm font-semibold text-muted-foreground">
              بانتظار المراجعة
            </p>
            <p className="mt-1 text-2xl font-extrabold">{workers.length}</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-5">
            <p className="text-sm font-semibold text-muted-foreground">الحالة</p>
            <p className="mt-1 text-2xl font-extrabold">
              {isLoading ? "تحميل" : "جاهز"}
            </p>
          </CardContent>
        </Card>
      </div>

      {isLoading ? (
        <Card>
          <CardContent className="p-6 text-muted-foreground">
            جاري تحميل الصنايعية...
          </CardContent>
        </Card>
      ) : workers.length === 0 ? (
        <Card>
          <CardContent className="p-8 text-center">
            <p className="text-lg font-bold">لا توجد حسابات معلّقة</p>
            <p className="mt-1 text-sm text-muted-foreground">
              أي صنايعي جديد سيظهر هنا للمراجعة.
            </p>
          </CardContent>
        </Card>
      ) : (
        <div className="grid gap-4">
          {workers.map((worker) => {
            const isApproving =
              actionState?.workerId === worker.user_id &&
              actionState.type === "approve";
            const isRejecting =
              actionState?.workerId === worker.user_id &&
              actionState.type === "reject";
            const isBusy = Boolean(actionState);

            return (
              <Card key={worker.user_id}>
                <CardContent className="p-5">
                  <div className="flex items-start justify-between gap-4">
                    <div>
                      <p className="text-lg font-bold">{worker.full_name}</p>
                      <p className="text-sm text-muted-foreground">
                        {worker.profession} • {worker.area}، {worker.governorate}
                      </p>
                    </div>
                    <Badge variant="secondary">
                      {worker.years_experience} سنة خبرة
                    </Badge>
                  </div>
                  <div className="mt-4 grid gap-1.5 text-sm text-muted-foreground">
                    <p>
                      <span className="font-semibold text-foreground">
                        الموبايل:
                      </span>{" "}
                      <span dir="ltr">{worker.phone}</span>
                    </p>
                    <p>
                      <span className="font-semibold text-foreground">
                        العنوان:
                      </span>{" "}
                      {worker.address}
                    </p>
                    <p>
                      <span className="font-semibold text-foreground">نبذة:</span>{" "}
                      {worker.bio}
                    </p>
                    <p>
                      <span className="font-semibold text-foreground">
                        تاريخ التسجيل:
                      </span>{" "}
                      {new Date(worker.created_at).toLocaleDateString("ar-EG")}
                    </p>
                  </div>
                  <div className="mt-4 flex flex-wrap gap-2">
                    <Button
                      disabled={isBusy}
                      onClick={() => onApprove(worker.user_id)}
                    >
                      <UserCheck />
                      {isApproving ? "جاري الاعتماد..." : "اعتماد"}
                    </Button>
                    <Button
                      variant="destructive"
                      disabled={isBusy}
                      onClick={() => onReject(worker.user_id)}
                    >
                      {isRejecting ? "جاري الرفض..." : "رفض"}
                    </Button>
                  </div>
                </CardContent>
              </Card>
            );
          })}
        </div>
      )}
    </div>
  );
}

function CenteredCard({
  title,
  description,
}: {
  title: string;
  description?: string;
}) {
  return (
    <main className="mx-auto flex min-h-screen w-full max-w-md items-center px-4">
      <Card className="w-full">
        <CardHeader>
          <p className="text-xs font-extrabold uppercase tracking-widest text-primary">
            Handy Admin
          </p>
          <CardTitle>{title}</CardTitle>
          {description ? (
            <CardDescription>{description}</CardDescription>
          ) : null}
        </CardHeader>
      </Card>
    </main>
  );
}

function Feedback({ message, error }: { message: string; error: string }) {
  if (!message && !error) {
    return null;
  }

  return (
    <div
      className={cn(
        "mb-4 rounded-xl px-4 py-3 text-sm font-bold",
        error
          ? "bg-destructive/12 text-destructive"
          : "bg-success/12 text-success",
      )}
    >
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

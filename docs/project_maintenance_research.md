# PetTomo 專案維護研究

研究日期：2026-10-22。程式基準：`4d1fef8`。

本文件是按現有程式、測試、事故紀錄及官方文件整理的建議，並非已啟用的維護政策。
本次只更新文件；沒有修改 app、部署 backend、設定通知或建立定時工作。
線上 Crashlytics、Supabase、ASC、商店及備份狀態均未重新查驗。

## 結論與優先次序

現有架構已有不少防線。最值得投入的是讓「發現問題 → 重現 → 修正 → 發佈 → 線上驗證」完整閉環，
並加強非同步、舊狀態及跨層契約的測試。暫時沒有足夠證據支持全面重寫或更換狀態管理。

| 優先 | 建議工作 | 依據與預期效果 | 完成證據 |
| --- | --- | --- | --- |
| P0 | 跟進已修正但未驗證的事故，安排下一個獲批 build | 登入、家具、揀相修正均在 build 32 封存後提交；避免程式已合併、用戶仍遇到舊 bug | 修正 commit 對應實際 build、真機結果及該版本的線上觀察 |
| P0 | 核實 Crashlytics 通知接收者、符號與支援收件流程 | 已有 telemetry，但 repo 不能證實通知有開、有人收到 | 測試 build 的可讀事件、通知接收證據、待辦中的 dSYM 查驗結果 |
| P1 | 先落實既有完整檢查，再評估最小 CI | pre-push 沒有執行測試，也不能驗證每個 clone 都啟用 hook | 最終提交有對應檢查結果；若啟用 CI，新 clone 可重現相同結果 |
| P1 | 將回歸測試集中在競態、重啟、授權及舊契約 | 最近事故涉及 auth stream、延遲寫入、native picker、舊佇列 | 舊實作能重現失敗，修正後通過；backend 行為另有隔離環境證據 |
| P1 | 補齊部署設定與復原證據 | migration 已版本化，但沒有 checked-in Supabase config | 可追溯 deployed version／auth 設定；已驗證的相容修復及還原步驟 |
| P2 | 每月小批更新依賴、按事故局部整理大檔案 | Home／Chat 集中大量狀態與非同步流程，native plugin 有 SPM 同步要求 | 每次一項可解釋的改動、相關回歸及既有最終檢查通過 |

## 目前已確認的基礎

- App 按 Home、Chat、Feed、Shop 等 feature 分工，使用 Riverpod、Hive、Supabase；
  目前產品只發佈 iOS。Home／Chat／Shop 以主檔與 `part` 分拆，不能把檔案分拆等同狀態已解耦。
  來源：[架構](../memory-bank/architecture.md)、[技術堆疊](../memory-bank/tech-stack.md)。
- 快照有 135 個 `_test.dart` 檔案；最近任務紀錄為 777 tests passed、1 live integration skip，
  **本次沒有重跑，亦沒有量度 coverage**。已有登入復原、家具延遲回應、feed 重試／重啟對帳等測試，
  不是只測成功路徑。來源：[任務紀錄](../tasks/todo.md)、
  [auth 測試](../test/services/auth/session_recovery_test.dart)、
  [家具測試](../test/features/home/home_furniture_placement_test.dart)、
  [queue 測試](../test/features/feed/feed_upload_queue_test.dart)。
- [pre-push](../.githooks/pre-push) 會檢查提交範圍內的 Markdown links、Dart format，
  有相關 Dart 檔案才執行 analyze；不執行 tests。本 clone 的 `core.hooksPath` 已是 `.githooks`。
  唯一 tracked GitHub workflow 是 [Apple secret 提醒](../.github/workflows/apple_key_reminder.yml)，
  不是測試 CI；是否正常排程／寄達沒有查驗。完整驗證規則以 [testing](testing.md) 為準。
- [CrashReportingService](../lib/services/crash/crash_reporting_service.dart) 已記錄版本、route、feature、
  room、last action、network state；[統一錯誤處理](../lib/shared/errors/user_facing_error.dart)
  對已處理錯誤作分類、non-fatal 回報及兩分鐘去重。先沿用現有入口，避免另建一套 logger。
- [UncleanExitService](../lib/services/crash/unclean_exit_service.dart) 在下次開啟 app 時推斷前景異常退出；
  memory warning 只是懷疑 OOM 的依據，並非事故當刻的原生 stack 或已證實原因。
- 已有相容性、feed、release、support runbook；現有強項是保留舊欄位、權威回應、時間戳防倒退及持久化對帳。
  來源：[合作／契約規則](ai_collaboration_workflow.md)、[feed pipeline](feed_upload_pipeline.md)、
  [release ledger](release_status.md)、[support inbox](support_inbox.md)。

## 從現有事故選擇預防措施

| 實際線索 | 容易再犯的模式 | 最小維護措施 |
| --- | --- | --- |
| `73cad68`：auth token refresh stream errors | 處理 Future 失敗，但漏了 stream 的錯誤／後續復原 | 所有手動 auth 訂閱維持 onError；測暫時失敗保留 session、失效 session、再次登入 |
| `2508637`：家具庫存／placement recovery | 寫入未完成時移除、舊 reload 覆蓋新狀態、回應落到已切換的 room | 延遲與反序回應測試；驗證 captured room、pending reservation 及最後 server snapshot |
| `4d1fef8`：photo picker loading timing | 把 native 選取時間同 app decode 時間混在一起；取消／dispose 後回呼 | 保留快／慢／取消／離頁測試，真機另驗 native gallery、camera、iCloud |
| feed runbook 的「後端已加飽食但畫面不動」 | 不同 realtime／refetch 回應互相覆蓋 | 沿用 authoritative write response 與 freshness guard；測舊 snapshot 晚到、重啟後對帳 |
| release ledger 的歷史 dSYM 遺失 | 正確腳本存在，但實際發佈入口沒執行；後續 build 覆蓋 archive | 驗證實際發佈路徑，沿用現有 upload／archive 關卡並核對可讀事件 |
| 架構記錄過 `.env` 被打包、其後輪替 | 秘密寫在 Git 以外，仍可經 app asset 洩漏 | 維持 `.env.app` allowlist 與 bundle 檢查；保留 [現有防線測試](../test/app_env_allowlist_test.dart) |

以上是程式歷史與文件中的案例，不代表本次證實線上仍然發生。
歷史原因參見 [regression archive](../tasks/archive/lessons_20260913.md)；
現行規則仍以各 canonical runbook 為準，不在此重寫一份。

## 測試如何花得最值得

優先延伸現有測試，讓一個曾發生的事故至少有一項會阻止它再發生的行為檢查。
Flutter 官方建議大量 unit／widget 加上足夠覆蓋重要情境的 integration tests；
不同層級的速度與維護成本不同。[官方測試指引](https://docs.flutter.dev/testing/overview)

| 邊界 | 要驗證的行為 | 沿用入口／仍缺的證據 |
| --- | --- | --- |
| Auth | token 失效、網絡暫時失敗、stream 後續仍可登入 | 現有 session recovery tests；下一版真機驗收仍待完成 |
| Feed | 重複按、timeout、server 已完成但回應遺失、重啟對帳、舊狀態不倒退 | queue／reconciliation／freshness tests；真實跨層驗證另按 testing 授權邊界 |
| Room／家具 | 切房、離頁、延遲／反序回應、庫存不足、斷線恢復 | 現有 placement harness 與 provider tests；不是只比對畫面字串 |
| DB／金幣／購買 | active member 可用、非成員／已退出不可用、重複請求不重複發獎；原有 RPC 參數與回傳型別可用 | 現有 SQL checks、migration／source guards；真實 RLS／transaction 仍需本機或隔離測試環境驗證 |
| 原生與記憶體 | picker／權限／通知、背景返回、多張大圖與長聊天 | 少量 iPhone smoke checks；widget mocks 無法代替 OS／真實記憶體行為 |
| 資產與相容性 | 舊 app fallback、最低版本前後、nested asset 包入 bundle | 現有 catalog／animation／compatibility tests，加 testing 所列 bundle 驗證 |

保留必要的 source-text guards（尤其部署 runtime 難以本機重現的 Edge Function 契約），
但它們不能證實實際 RLS、交易或 native 行為。家具測試雖讀取 source，實際會執行抽出的 production methods，
不應一律當成字串測試。只在修改相關功能時，以實際輸入／輸出補足弱項，避免全面重寫測試。

Supabase 官方提供 client 與 SQL／pgTAP 測試路線。建議先沿用既有 SQL checks，在隔離環境補關鍵角色與交易案例；
不用為了引入新框架而搬移全部測試。[官方 DB testing](https://supabase.com/docs/guides/database/testing)

### 最小自動檢查方案（尚未實作）

1. 現時立即可做：每次 executable／asset 改動仍按 [testing](testing.md) 的最終格式、分析、測試順序執行，
   把 commit 與結果記錄在該任務；focused tests 不能取代完整關卡。
2. 下一步才評估一個 PR／push 測試 workflow：沿用 `.fvmrc` 的 SDK，重用相同檢查，測試依序執行；
   自動檢查失敗就不進入發佈。若要成為強制合併關卡，還須另設 branch protection，單有 workflow 不足夠。
3. 先在乾淨 checkout 證實可用安全 test fixtures 產生 gitignored Firebase options 與 public client config；
   不把 production server secrets 放入 CI。現有 live test 亦會讀 `.env`，只清空 process env 並不足以隔離它；
   日常 CI 不提供 live refresh token。有寫入的 live／SQL／webhook tests 維持獨立授權入口。

本次只驗證了文件及腳本內容，沒有證實乾淨環境 bootstrap 或 CI 可以跑通。

## 及時發現與維修

### 建議的處理節奏

以下是供負責人採用的工作節奏與目標，未建立排程或承諾全天候值班。
先指定主要維護者與通知可觸達的後備人；單人維護就明確記錄可處理時段。

| 時間 | 工作 | 輸出 |
| --- | --- | --- |
| 每個工作日約 10–15 分鐘 | 查看新／regressed fatal、核心 non-fatal、support 回報；按版本與受影響人數排序 | 新事故有嚴重度、負責人及下一步；必要時查相關 Supabase logs |
| 每次 app 發佈／backend 部署後 | 當日、24 小時、72 小時查看該版本／功能；流量不足再延長至一週 | 記錄採用量、是否再現及資料不足，不能以零事件直接結案 |
| 每週約 30 分鐘 | 對照未結案事故、已合併未發佈修正、USER ACTION REQUIRED、最近失敗測試 | 優先處理影響最大或重複出現的 1–3 項，標明下一個 build／驗證日期 |
| 每月 | 小批依賴／SDK 更新、Apple secret 提醒是否運作、備份／還原證據與未用程式 | 一個可回退的小批更新；復原演練先在隔離環境安排 |

Crashlytics 並非所有通知都預設寄送；new fatal／non-fatal 與 velocity 要核實設定。
Velocity 有人數門檻，低流量 app 即使有嚴重個案亦可能不觸發；每日檢視與 support 仍必要。
此處未查驗 PetTomo 的實際訂閱。[Firebase alerts](https://firebase.google.com/docs/crashlytics/alerts-default)

`[USER ACTION REQUIRED]`：核實目前的通知接收者／設定與待辦中的 Missing dSYMs dashboard 結果，
並完成下一版 native picker、auth recovery、家具操作真機驗收。
不必等到下次事故才確認有沒有通知；如要製造測試事件，只限合適的測試 build／測試帳號。
Firebase 的 Flutter 設定指引亦把錯誤捕捉與符號處理列為驗收內容。
[Crashlytics for Flutter](https://firebase.google.com/docs/crashlytics/flutter/get-started)

### 建議分級與結案條件

| 級別 | 例子 | 建議反應（有人可處理時） |
| --- | --- | --- |
| P0 | 可信的金幣／購買錯帳、資料遺失、跨房間資料外洩、大量用戶無法啟動／登入 | 收到後立即調查；優先止損。單一可信個案已足夠，不等待累積人數 |
| P1 | 可重現的核心 feed／join／家具流程阻塞、明顯新增 crash | 當日定位及提供 workaround／修復計劃，優先安排相容 server 修復或下一版 |
| P2 | 可繞過的局部問題、輕微顯示或較低影響退化 | 下一次每週 triage 排序，指定版本或清楚延後原因 |

事故紀錄最少包括：issue／回報來源、首次觀察時間、發現時間、app version＋build、受影響功能／人數、
重現步驟、責任人、根因、regression test、fix commit、修復部署或發佈時間、復原證據與待驗項目。
不保存照片、token 或完整私人訊息；重用既有支援 meta、route、source 及匿名識別。

建議狀態：待重現 → 已重現 → 已修正 → 已部署／已發佈 → 線上驗證完成。
結案要看到對應 build／server version 已覆蓋受影響範圍，且觀察期有足夠使用量；
未發佈、未採用、低樣本或缺少真機證據的項目，保留「待驗證」。

app 修復需要下一個未使用的 build number；build 32 已封存／上傳，不能因 `pubspec.yaml` 仍是 32 就當成包含之後的修正。
商店當前狀態需另查；本研究不授權 build、上傳或 App Review submission。
實際狀態繼續只記錄於 [release ledger](release_status.md)，避免另一份表漂移。

## Backend 與發佈如何降低風險

沿用 [既有契約／部署規則](ai_collaboration_workflow.md)，對高風險變更補足以下證據：

- **Migration 可重播性**：先評估現有 149 份 migration 是否能在隔離本機環境重建；
  沒有測過就不能當成已有 staging 或可復原基線。只為關鍵路徑加入必要 fixture，不複製用戶資料。
  Supabase 官方建議 versioned migrations 與環境分段驗證；這不取代本 repo 的 MCP／批准規則。
  [Managing Environments](https://supabase.com/docs/guides/deployment/managing-environments)
- **部署設定可追溯**：目前沒有 `supabase/config.toml`，不推斷線上設定。
  建議在既有部署紀錄補核實的 function version、verify_jwt、必要 secret 名稱、auth 拒絕案例及 last-known-good source；
  secret 值繼續留在秘密管理中。官方依 user JWT、server、webhook 分不同 auth 路徑；
  不可為求一致把所有 function 改成相同 verify_jwt。
  [Securing Edge Functions](https://supabase.com/docs/guides/functions/auth)
- **復原路徑**：app 記錄上一個可用 build、修正版及採用情況；已安裝 app 不會因 Git revert 自動復原。
  server 先評估舊客戶端影響，再以相容修正 migration 或經批准的上一版 function 處理。
  金幣／資料寫錯先保留證據；資料還原及補償要另有明確範圍與批准，不自動執行 destructive down migration。
- **還原能力**：先查實際備份方案、保留期及可接受資料損失／恢復時間，再在隔離環境安排還原演練。
  本次未驗證備份存在、PITR 可用或可成功還原，不承諾復原時限。
- **iOS native 更新**：小批更新 plugin，同步 lockfiles 與 SPM resolved paths，再走既有真機／archive 檢查。
  不為減少 bug 而一次升級全部依賴。具體限制見 [tech stack](../memory-bank/tech-stack.md)。

## 只量度能支持決策的指標

先用 Crashlytics、support 及現有任務／release 紀錄做兩週基線，避免先建新 dashboard 或加大量 telemetry。

| 指標 | 定義／用法 | 限制 |
| --- | --- | --- |
| 用戶影響 | 按版本看 crash-free users／sessions，以及 fatal／non-fatal 的受影響人數 | 已處理錯誤與合成 unclean-exit 另看；兩分鐘去重後的事件數不等於操作失敗次數 |
| 流程失敗 | feed／登入／購買等核心功能的已確認失敗個案及成功率（若有可靠分母） | 尚未驗證完整成功／嘗試計數；沒有分母就報個案數，不捏造成功率 |
| MTTD | 首次可觀察異常到維護者發現的時間 | telemetry 可能延遲；unclean exit 要等下次啟動，註明時間來源 |
| 恢復時間 | 維護者發現到受影響功能恢復的時間；另記錄發佈及採用等待 | fix commit 不是服務恢復；客戶端受 app 審核／採用影響 |
| 重複事故 | 已確認相同根因再次發生的事故數，按週／版本看 | 區分舊版本仍在使用與新版本 regression，不只按 issue title 合併 |
| 維護積壓 | P0／P1 未結案天數、已合併未發佈修正數、待真機／線上驗證數 | 先縮短積壓，不以測試數量增加代替品質改善 |

## 建議的首月落地次序

1. **第 1 週：縮短修正交付時間。** 指定維護者、核實通知，整理現有待驗事故；
   下一個獲批 build 納入近期修正並完成必要真機檢查。既有批准只按原範圍沿用。
2. **第 2 週：消除漏跑檢查。** 在乾淨環境建立安全 bootstrap，驗證最小測試 CI 可行性；
   補最常出事功能的 1–2 個缺失行為案例，不能把已存在的測試重新當成果。
3. **第 3 週：驗證 backend 邊界與復原。** 評估 migration replay、關鍵角色／冪等測試、部署設定及備份；
   所有寫入測試先確認隔離目標，production 變更仍走既有批准。
4. **第 4 週：用基線調整投入。** 看事故重複率、發現／恢復時間及待驗積壓，決定下一個小範圍改善。
   Home 主檔 3,594 行、Chat 主檔 2,748 行只是維護熱點線索，不是全面重構理由；
   只在同一責任反覆出錯時，沿現有 controller／provider 邊界移動最小一段並保留行為測試。

以上週次是先後順序建議，不是已安排的工作、工時承諾或已批准的部署。

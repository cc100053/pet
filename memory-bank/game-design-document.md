# PicPet Refined - 產品開發企劃書 (Master Plan)

- 版本： v2.0 (The Development Bible)
- 日期： 2026-01-01
- 項目負責人： NAM
- 技術顧問： Gemini

## 1. 產品概述 (Product Overview)
- 產品名稱： PicPet (暫定)
- 核心價值： 一款基於「真實相片互動」的社交寵物養成遊戲。強調異地共養、情感連結與 AI 智能反饋。
- 目標平台： iOS & Android (Flutter 跨平台開發)
- 目標市場： 台灣、香港、日本 (首發)，隨後擴展至全球。
- 語言支援： 繁體中文、日文 (首發)；英文 (後續更新)。
- 開發目標： 打造比競品 (PicPet/Widgetable) 更具「手感」與「生命力」的共養體驗。

## 2. 用戶系統與配對 (User & Pairing)

### 2.1 帳戶體系
- 登入方式 (Login)：僅支援 Google Sign-In 與 Apple Sign-In (無 Email/Password 選項以簡化流程)。
- 個人檔案 (Profile)：
  - 暱稱：用戶自定義。
  - 頭像：系統提供幾款預設風格化頭像，或用戶上傳自定義圖片。
- 刪除帳號 (Deletion)：
  - 符合 App Store 規範，提供刪除按鈕。
  - 歸屬權邏輯：若用戶 A 刪除帳號，其與用戶 B 共養的寵物及房間數據完整保留，所有權自動轉移給用戶 B。

### 2.2 房間與配對機制
- 邀請碼邏輯：
  - 由後端生成 6 位數隨機數字。
  - 唯一性檢查 (Unique Check)：生成後即時比對 Database，確保不與現有房間重複。
  - 時效：有效期 60 分鐘，過期需重新生成。
  - 權限規則：只有房主 (Owner) 可生成/更新邀請碼並分享給其他人；一般成員不可生成邀請碼。
- 多房間系統 (Multi-room)：
  - 免費版：上限 2 個房間。
  - 付費版 (訂閱)：無限 房間。
  - 新增邏輯：若免費版已滿，點擊「新增房間」按鈕時彈出付費訂閱視窗 (Upsell)。
- 單人/多人模式：
  - 支援單人遊玩 (自己開房自己養)。
  - 隨時可邀請朋友加入現有房間。
  - 若其中一人離開房間，房間數據保留給剩下的人，不會被刪除。
  - 房主轉移：若房主離開或刪除帳號，房主權限自動轉移給仍在房間的成員；若房間無房主，下一位加入者成為房主。

## 3. 寵物系統與數值策劃 (Pet & Stats)

### 3.1 生成與成長
- 初始狀態：寵物蛋 (Egg)。
- 孵化邏輯 (Color DNA)：
  - 基於玩家餵食照片的 主色調 (Dominant Color) 決定孵化結果。
  - 例子：餵食多張藍色物品 (天空、大海、藍莓) -> 孵出藍色系寵物。
  - 技術：使用 Flutter palette_generator 分析圖片。
- 成長：寵物體型隨「天數」與「等級」按比例變大 (Scale up)。
- 命名：雙方隨時可更改寵物名字。

### 3.2 數值狀態機 (State Machine Details)
- 所有數值計算以 後端 (Supabase) 為準，前端同步顯示。

#### A. 飽食度 (Hunger)
- 範圍：0 - 100。
- 自然消耗：基礎 -5 點 / 小時。
- 心情修正 (Mood Modifier)：
  - 心情 High：-3 點 / 小時 (消耗減慢)。
  - 心情 Mid：-4 點 / 小時。
  - 心情 Low：-5 點 / 小時。
  - 心情 Sad (且有大便未清理)：-6 點 / 小時 (消耗加快)。
- 夜間保護機制 (Night Mode)：當玩家手機時間位於 00:00 - 08:00，代謝率減半 (數值消耗 *0.5)。
- 過飽機制：若短時間多次餵食，觸發對話「好飽呀～」，不扣心情但不加數值。

#### B. 心情 (Mood)
- 等級：Low (普通) -> Mid (開心) -> High (超開心) -> Sad (悲傷/生病)。
- 提升方式：摸頭 (Touch) / 餵食 (Feed) / 洗澡 (Clean)。
- 每個動作提升 1 個等級。
- 持續時間：提升後的心情等級持續 1 小時，隨後自動降回原等級 (或視乎飽食度調整)。
- 操作冷卻 (Cooldown)：對同一動作 (如摸頭)，需間隔 2 小時 才能再次獲得心情提升效果 (防止刷分)。

#### C. 清潔度 (Hygiene)
- 排泄機制：
  - 頻率：每天 1-2 次 (隨機觸發，或累積餵食 3 次後觸發)。
  - 設計意圖：降低頻率以免造成用戶困擾 (Notification Spam)。
- 懲罰機制：若大便存在超過 2 小時 未清理，心情每 2 小時降一級，直到變 Sad。
- 夜間保護機制 (Night Mode)：當玩家手機時間位於 00:00 - 08:00，不因大便未清理而扣心情。
- 視覺表現：寵物變色、周圍有蒼蠅動畫。

#### D. 睡眠 (Sleep)
- 跟隨寵物內置生理時鐘 (隨機性)，純視覺動畫 (Idle Animation)，不影響玩家互動操作 (睡覺時仍可強行餵食，但會顯示睡眼惺忪的樣子)。

## 4. 經濟系統 (Economy)

### 4.1 貨幣 (Coins)
- 獲取途徑：
  - 餵食：+10 Coins。
  - 清理大便：+5 Coins。
  - 摸頭：+1 Coin。
- 獲取限制：每種動作 每小時只能獲得一次 金幣獎勵 (防止腳本刷錢)。
- 每日任務獎勵：完成 Daily Quest (如：影雪糕) -> 獲得 雙倍金幣 (+20)。

### 4.2 消費與死亡機制
- 商店內容：寵物家具、背景牆紙 (Cosmetic)。
- 離家出走 (Death)：
  - 條件：飽食度歸 0。
  - 結果：寵物消失，留下告別信。
  - 挽回方式：需購買付費道具 「家書 (Letter)」 (單次內購) 將其喚回。

## 5. 核心玩法與 AI 識別 (Gameplay Loop)

### 5.1 餵食流程 (Feeding Flow)
- 觸發：點擊聊天室底部左側的 [📷 相機] 按鈕。
- 輸入：拍照或從相簿選擇 (允許非實時照片)。
- AI 處理 (Local)：使用 Google ML Kit 進行 Object Detection。
- Label 映射層 (Mapping Layer)：
  - ML Kit 產生英文標籤 (e.g., "Cup", "Beverage")，需在 App 端或後端轉譯/模糊匹配至中/日/英任務詞彙，避免任務判定落差。
  - 映射字典：以 `label_mappings` / `quests` 表為基準維護，初版詞彙見 memory-bank/label-mapping.md。
- 結果確認 (Modal)：
  - 顯示預覽圖與識別標籤 (Label)。
  - Caption 輸入框：選填 (Optional)。
- 判定邏輯：
  - 任務匹配 (Match)：如任務是 "Coffee"，AI 識別出 "Drink/Cup" -> 成功 (+20 Coins, Mood Up)。
  - 非任務 (Normal)：AI 識別出任何物件 -> 成功 (+10 Coins, Mood Up)。
  - 識別失敗 (Unknown/Fail)：AI 信心分數過低 -> 當作普通分享 (無 Coins, 無 Mood 變化, 但照片仍發送至聊天室)。
- 冷卻檢查：若 1 小時內已獲獎勵，則僅發送照片，不加金幣。
- 客戶端預處理 + 後端驗證 (Optimization)：
  - App 端先壓縮圖片 (WebP, 80% quality) 並取得 Labels，再將 Labels + 圖片上傳至 Supabase Edge Function。
  - 不要把判斷邏輯全放在前端，避免被竄改；由後端驗證 Labels 是否符合任務。

### 5.2 內容審查 (Safety)
- 工具：Google ML Kit Image Labeling (內建 Safe Search)。
- 邏輯：若偵測到 Adult, Violence 等敏感標籤且信心分數 > 0.7 -> 前端直接攔截，彈出警告，禁止上傳。

## 6. 聊天室與回憶 (Chat & Memory)

### 6.1 混合事件流 (Hybrid Stream)
聊天室是遊戲的「客廳」，整合以下三種訊息：
- 文字對話：用戶輸入的 Chat。
- 餵食記錄：帶有特殊邊框的照片卡片 (顯示：[圖片] +10 Coins)。
- 系統事件：灰色小字 (如：「B君 幫忙清理了大便」)。

### 6.2 技術實作細節
- 即時性：Supabase Realtime。
- 加載策略：
  - 分頁 (Pagination)：首次加載最新 20 條。
  - 懶加載 (Lazy Loading)：滑動到頂部時，自動加載舊的 20 條。
- 圖片儲存 (Cloudflare R2)：
  - 壓縮：App 端強制轉為 WebP 格式，目標大小 100KB。
  - 保留策略：永久保存，不過期。
  - 快取：前端使用 cached_network_image，避免重複消耗流量。

### 6.3 圖鑑/回憶錄
- 形式：月曆視圖 (Calendar View)。
- 數據：直接從聊天記錄中篩選 type = image_feed 的訊息進行展示。
- 功能：點擊可查看大圖並下載。

## 7. UI 交互規範 (UI/UX)

### 7.1 主介面 (Home) - 沉浸式疊層
- 採用 Stack 佈局：
  - Layer 1 (底層)：房間背景圖。
  - Layer 2 (中層)：Lottie 寵物動畫 (位於畫面中央偏上)。
  - Layer 3 (頂層)：可拖動底板 (DraggableScrollableSheet)，承載聊天室。
- 互動：點擊寵物觸發 Bounce 動畫；長按顯示狀態數值。
- 初始高度：40% (露出寵物)。
- 最大高度：90% (全屏閱讀)。
- 背景：毛玻璃 (Blur) 半透明效果。
- 手勢衝突修正：
  - 為避免 DraggableScrollableSheet 與聊天室 ListView 滑動衝突，採「未全開禁止 ListView 滾動」或「專用 Grab Handle 才能拖動面板」的設計。

### 7.2 輸入欄 (Input Bar)
- 固定在 Layer 3 底部。
- 佈局：[📷 相機 (高亮色)] - [ 輸入框 (佔 80%) ] - [發送]。
- 相機按鈕：置於最左側，設計上需突出，引導用戶點擊。

### 7.3 側邊選單 (Drawer)
- 點擊左上角漢堡包圖示滑出。
- 顯示所有房間列表 (免費版 2 個)。
- 點擊 [+] 新增房間 若額滿，直接跳轉訂閱頁面。

## 7.4 設計師交付範圍 (MVP Design Checklist)
目的：先滿足核心玩法與首輪商業化測試，交付可用於開發與驗收的設計與素材。

### 7.4.1 MVP 設計範圍
- 核心流程：登入/註冊、建立房間、輸入邀請碼加入、主畫面聊天/餵食、每日任務提示。
- 主要頁面：Home (寵物 + Chat)、Room List/Drawer、Feed 確認彈窗、Memory 月曆、Store、Settings、訂閱 Upsell。
- 狀態稿：空狀態 (無訊息/無任務/無房間)、載入中、錯誤/離線、成功提示。
- 元件庫：聊天氣泡、照片卡片 (含 +Coins)、系統事件卡、狀態數值提示、Grab Handle、相機按鈕。
- 廣告/內購：Rewarded ad 彈窗、訂閱方案比較卡、付款成功/失敗回饋。
- 多語系：中文/日文主要字串版面確認，避免文字溢出。
- 動效指引：Lottie 動畫進場/互動規範與 UI 動畫節奏。

### 7.4.2 交付清單 (Deliverables)
- 介面設計：主要畫面與狀態稿。
- 元件庫：可重用 UI 元件與樣式。
- Pet 本體：寵物造型與基本狀態 (Lottie / PNG)。

### 7.4.3 交付指引 (非 Figma 使用者適用)
- 可交付 PNG (透明底) / SVG / JPG / PDF 圖檔。
- 建議輸出 2x/3x 尺寸，避免放大失真。
- 分件輸出：背景、按鈕、icon、Pet 本體分開。
- 命名清楚：如 `home_bg.png`、`btn_camera.png`、`pet_idle.png`。

### 7.4.4 素材格式規格表
| 素材類型 | 格式 | 說明 |
| --- | --- | --- |
| Icon / 線條圖形 | SVG | 可縮放不失真，適合 UI 元件 |
| 背景 / 大圖 | PNG (2x/3x) | 複雜質感或插畫 |
| 照片卡片 | PNG/JPG | 視覺層素材 |
| Pet 靜態圖 | PNG | 無動畫時使用 |
| Pet 動畫 | Lottie (.json) | 由向量分層素材製作 |

### 7.4.5 Lottie 素材建議
- 最佳素材：分層 SVG/AI (身體、眼、口、手腳、飾品獨立)。
- PNG 只適合靜態或逐格動畫，放大易糊、不易做骨骼動畫。
- 避免複雜濾鏡/模糊，文字需轉 outline。

## 8. 商業化 (Monetization)

### 8.1 廣告 (Ads)
- 插屏廣告 (Interstitial)：改為可選的「雙倍獎勵」激勵視頻流程：
  - 餵食完成 -> 獲得 10 Coins -> 彈窗「看廣告獲得雙倍 (20 Coins)？」-> 用戶主動點擊播放。
- Banner 廣告：僅在「設定」或「商店」頁面底部，不干擾主遊戲區。
- 激勵視頻 (Rewarded)：主動觀看以獲得金幣或縮短冷卻時間。

### 8.2 內購 (IAP)
- 訂閱 (Subscription)：去除所有廣告 + 無限房間。
- 消耗品 (Consumable)：
  - 金幣包。
  - 房間名額擴充。
  - 家書 (Letter)：復活道具。

## 9. 風險控制與合規 (Risk & Compliance)
- 舉報機制 (Report)：在聊天室中長按對方訊息/圖片，需彈出「舉報」與「封鎖」選項 (App Store 必須)。
- 隱私聲明：條款需註明「我們嚴格保護用戶隱私，不會主動查看用戶內容」 (保留運維所需的最低限度權限)。
- RLS Policies (Supabase)：
  - 必須啟用 Row Level Security，確保用戶只能讀取自己房間資料。
  - 例：SELECT * FROM messages WHERE room_id IN (SELECT room_id FROM room_members WHERE user_id = auth.uid())。
- 強制更新 (Force Update)：App 啟動時檢查 Supabase app_config 表中的 min_version，若低於此版本，強制彈窗跳轉商店更新。
- 離線處理：斷網時，聊天室訊息顯示「發送中...」或「紅色感嘆號」，允許重試。

## 10. 技術棧清單 (Tech Stack Checklist)
- Frontend: Flutter (Dart)
- State Management: Riverpod
- Animation: Lottie (lottie package)
- Local DB: Hive (for local cache & settings)
- Backend: Supabase (Auth, Postgres DB, Realtime)
- Storage: Cloudflare R2 (S3 compatible API)
- Push Notification: Firebase Cloud Messaging (FCM)
- AI: Google ML Kit (google_mlkit_image_labeling, google_mlkit_object_detection)
- Analytics: Firebase Analytics (Default)

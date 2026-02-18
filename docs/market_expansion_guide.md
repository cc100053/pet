# Market Expansion Guide: South Korea, US, Australia, Canada

This guide provides step-by-step instructions for addressing the specific requirements when expanding your app's availability to South Korea, the United States, Australia, and Canada.

## 1. South Korea: Game Rating & Administration Committee (GRAC)

South Korea has strict regulations regarding game ratings. However, for many casual games like **PetTomo**, the process is streamlined.

### Step-by-Step Fix:
1.  **Log in to App Store Connect**.
2.  Go to **My Apps** -> Select **PetTomo**.
3.  In the sidebar, click on **App Information**.
4.  Scroll down to the **Age Rating** section.
5.  Click **Edit** next to the age rating.
6.  **Review the Questionnaire**:
    -   Ensure all answers are accurate.
    -   Pay special attention to **Gambling** and **Simulated Gambling**. If your game has "gacha" mechanics (random item boxes paid with real money), you *must* disclose this.
    -   For South Korea, if your game is rated **17+** (due to violence, gambling, etc.), you might be required to upload a specific **GRAC Rating Certificate**.
### Do I need an official GRAC Certificate?
**Most likely NO.**

South Korea has a "Self-Rating" system for Open Markets (like the App Store and Google Play).
-   **Exempt (Self-Rating)**: If your game is rated **4+, 9+, or 12+** by Apple, you **DO NOT** need a separate GRAC certificate. Apple's rating is accepted.
-   **Mandatory GRAC Rating**: You ONLY need an official certificate from the GRAC website (https://www.grac.or.kr) if:
    1.  Your game allows **betting/gambling** with real money or paid currency.
    2.  Your game has **Adult (19+)** content (extreme violence, explicit sexual content).
    3.  It is a casino-style game (Poker, Go-Stop).

### How to get an Official GRAC Rating (If required):
*Note: This is a complex process requiring a Korean business license and fee payment.*
1.  **Register**: Go to the [GRAC Website](https://www.grac.or.kr).
2.  **Apply**: Submit game client, gameplay video, and design documents.
3.  **Pay Fees**: Fees vary by game genre and platform.
4.  **Wait**: Review takes 15-30 days.
5.  **Submit to Apple**: Once rated, enter the "Rating Classification Number" (e.g., CC-OM-240101-001) in App Store Connect -> App Information -> Age Rating.

**For PetTomo:**
Since this is a casual pet game, you should simply complete the **App Store Connect Age Rating** questionnaire honestly.
-   If the result is 4+, 9+, or 12+, you are **Done**. No external action is needed.

---

## 2. Tax & Banking: US, Australia, Canada

To sell apps or In-App Purchases (IAP) in these regions, you must have the "Paid Applications Agreement" active for them.

### Step-by-Step Fix:
1.  **Log in to App Store Connect**.
2.  Go to **Business** (formerly "Agreements, Tax, and Banking").
3.  Look at the **Agreements** tab.
4.  Check the **Paid Apps** row.
    -   **Status**: It should say **Active**.
    -   If it says **Action Required** or **New Terms**, click on it.
5.  **View and Agree to Terms**:
    -   Apple often updates the "Schedule 2" or "Schedule 3" for specific regions (like Australia or Canada).
    -   You may need to agree to the **Addendum** for these specific countries.
6.  **Tax Forms**:
    -   **United States**: You likely already completed the **W-8BEN** (for individuals) or **W-8BEN-E** (for companies) when you first set up your account. Double-check that it is **Verified**.
    -   **Australia/Canada**: Generally, you do *not* need to file separate tax forms with the Australian or Canadian governments if you are outside those countries. Apple handles the tax collection and remittance (tier 1 countries). However, verify if there are any pending **"Tax Info"** requests in the Business section.
7.  **Banking**:
    -   Ensure your existing bank account is selected for these new regions. Usually, one global bank account suffices, and Apple handles the currency conversion (paying you in your local currency).

### Verification:
-   Once the status is **Active**, you are good to go.
-   Updates can take up to 24 hours to process.

---

## 3. Privacy Policy (Global)

You have already updated your Privacy Policy to include English, Korean, Japanese, and Traditional Chinese.

-   **Action**: No further action needed. Your `privacy_policy_ko.html` covers the requirements for South Korea (PIPA).

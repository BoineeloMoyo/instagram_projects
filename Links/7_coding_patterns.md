# 7 Coding Patterns I Stole From Senior Engineers
> Most developers don't get better because they learn more syntax.  
> They get better because they **stop making code harder than it needs to be.**

---

## Pattern 1 — Return Early Instead of Building Conditional Mazes

### The Idea
Check for failure cases **first** and return immediately. Don't make the reader walk through five doors before finding the point. This is called a **guard clause**.
### The Junior Way — Nested Tunnel
```typescript
async function updateUserProfile(userId: string, input: ProfileInput) {
  const user = await getUser(userId);

  if (user) {
    if (input.email) {
      if (user.canEditProfile) {
        return saveProfile(user.id, input); // buried 3 levels deep
      }
    }
  }

  throw new Error("Unable to update profile"); // vague, unhelpful
}
```

### ✅ The Senior Way — Guard Clauses
```typescript
async function updateUserProfile(userId: string, input: ProfileInput) {
  const user = await getUser(userId);

  if (!user) throw new NotFoundError("User not found");
  if (!input.email) throw new ValidationError("Email is required");
  if (!user.canEditProfile) throw new ForbiddenError("User cannot edit profile");

  return saveProfile(user.id, input); // happy path is clean and obvious
}
```

### Key Takeaway
> Remove the failure paths early so the **real logic can breathe**.

---

## Pattern 2 — Name the Business Meaning, Not the Technical Accident

### The Idea
Name things after what they **mean to the business**, not what they technically contain. A variable called `subscription` tells the next developer far more than `result` ever could.

### The Junior Way — Vague Names
```typescript
const result = await getData(id);

if (result.status === "active") {
  await process(result); // what is result? what does process do?
}
```

### The Senior Way — Business Names
```typescript
const subscription = await getSubscription(subscriptionId);

if (subscription.isBillable) {
  await chargeSubscription(subscription); // crystal clear
}
```

### More Examples
```typescript
// ❌ Vague
const data = await fetchUsers();
const filtered = data.filter(u => u.flag === true);

// ✅ Meaningful
const allUsers = await fetchUsers();
const usersEligibleForReactivation = allUsers.filter(u => u.isInactive && !u.isDeleted);
```

### Key Takeaway
> Senior engineers name code so the **next developer doesn't have to reverse-engineer intent from implementation**.

---

## Pattern 3 — Put Boundaries Around External Chaos

### The Idea
Never let a third-party API, webhook, or vendor response become the language of your entire codebase. Create **one boundary** where outside chaos becomes inside language.

### The Junior Way — Leaking External Shape
```typescript
// This vendor shape now lives in 12 different files
const userName = response.data.user_name;
const isActive = response.data.status === "ACTIVE";
const plan = response.data.subscription.plan_name;

// Vendor renames user_name → customerName and everything breaks
```

### The Senior Way — An Adapter Boundary
```typescript
function mapBillingCustomer(response: BillingCustomerResponse): Customer {
  return {
    id: response.id,
    name: response.user_name,           // vendor field mapped once, here
    isBillable: response.status === "ACTIVE",
    planName: response.subscription?.plan_name ?? "Free"
  };
}

// The rest of your app only ever sees Customer — never the vendor's shape
const customer = mapBillingCustomer(response);
```

### The Rule
```
❌ Don't let raw DB rows leak into UI logic
❌ Don't let HTTP response shapes leak into domain logic
❌ Don't let Stripe, Slack, or GitHub become the language of your whole codebase
✅ One adapter per external system — chaos stays at the door
```

### Key Takeaway
> Never let systems you **don't control** define the shape of systems you **do control**.

---

## Pattern 4 — Make Invalid States Boringly Hard

### The Idea
Making every field optional just to stop TypeScript from complaining isn't type safety — it's surrender. Model your states honestly so **wrong usage becomes visible earlier**.

### The Junior Way — Everything Optional
```typescript
type User = {
  id?: string;      // is this a new user? a saved user? who knows
  email?: string;
  role?: string;
  status?: string;
};

// Now EVERY function has to ask the same anxious questions:
// Does this user have an ID? Is role defined? Can this be saved?
```

### The Senior Way — Honest State Modeling
```typescript
type DraftUser = {
  email: string;
  role: "admin" | "member";
};

type SavedUser = {
  id: string;         // id only exists on saved users
  email: string;
  role: "admin" | "member";
  status: "active" | "disabled";
};
```

### Union Types for Complex Flows
```typescript
type Payment =
  | { state: "pending";    id: string }
  | { state: "authorized"; id: string; authorizationId: string }
  | { state: "captured";   id: string; receiptId: string }
  | { state: "failed";     id: string; reason: string };

// Now this function can REQUIRE a captured payment at compile time
function sendReceipt(payment: Extract<Payment, { state: "captured" }>) {
  return emailReceipt(payment.receiptId); // safe — receiptId is guaranteed
}
```

### Key Takeaway
> Senior engineers don't just handle invalid states.  
> They design code so **invalid states have fewer places to hide**.

---

## Pattern 5 — Separate Decisions From Actions

### The Idea
Business logic (decisions) and side effects (actions) mixed together = tests that are impossible to write. Pull the **decision into a pure function** so rules can be tested without mocking the world.

### The Junior Way — Mixed Decision + Action
```typescript
async function refundInvoice(invoiceId: string) {
  const invoice = await getInvoice(invoiceId);

  // Decision buried inside action — to test this rule you need to
  // mock getInvoice, paymentProvider, markInvoiceRefunded, sendRefundEmail
  if (invoice.status !== "paid") throw new Error("Invoice cannot be refunded");
  if (invoice.refundedAt)        throw new Error("Invoice already refunded");
  if (invoice.amount <= 0)       throw new Error("Invalid refund amount");

  await paymentProvider.refund(invoice.paymentId);
  await markInvoiceRefunded(invoice.id);
  await sendRefundEmail(invoice.customerId);
}
```

### The Senior Way — Decision Separated
```typescript
// Pure function — no side effects, easy to unit test
function getRefundEligibility(invoice: Invoice): RefundEligibility {
  if (invoice.status !== "paid") return { allowed: false, reason: "Invoice is not paid" };
  if (invoice.refundedAt)        return { allowed: false, reason: "Invoice already refunded" };
  if (invoice.amount <= 0)       return { allowed: false, reason: "Invalid refund amount" };
  return { allowed: true };
}

// Action is now clean — just orchestrates
async function refundInvoice(invoiceId: string) {
  const invoice     = await getInvoice(invoiceId);
  const eligibility = getRefundEligibility(invoice); // testable in isolation

  if (!eligibility.allowed) throw new ValidationError(eligibility.reason);

  await paymentProvider.refund(invoice.paymentId);
  await markInvoiceRefunded(invoice.id);
  await sendRefundEmail(invoice.customerId);
}
```

### Key Takeaway
> Decisions should be **easy to test without triggering the side effects they control**.

---

## Pattern 6 — Make Errors Useful to the Next Person

### The Idea
"Something went wrong" helps nobody. Treat errors as **communication** — give the right people enough context to move fast.

### The Junior Way — Useless Errors
```typescript
// API response
{ "message": "Something went wrong" }

// Frontend forced to do this crime:
if (error.message.includes("already exists")) {
  showEmailTakenError(); // breaks if backend changes the wording
}
```

### The Senior Way — Structured Errors
```typescript
// API response
{
  "code":      "USER_EMAIL_ALREADY_EXISTS",
  "message":   "A user with this email already exists.",
  "details":   { "field": "email" },
  "requestId": "req_8f91a2"
}

// Frontend can now act on the code, not brittle text matching
if (error.code === "USER_EMAIL_ALREADY_EXISTS") {
  showEmailTakenError(); // safe — codes don't change with copy edits
}
```

### Structured Logging
```typescript
// ❌ Useless log
console.error("Refund failed");

// ✅ Traceable log
logger.warn("Refund rejected", {
  invoiceId,
  customerId,
  reason: eligibility.reason,
  requestId           // connects to the full request trace
});

// Never log: passwords, tokens, payment details, or personal data
```

### Key Takeaway
> Errors should help the next person understand **what failed, where it failed,  
> and what evidence connects the failure**.  
> Text is for humans. **Codes are for systems.**

---

## Pattern 7 — Optimize for the Diff, Not the Demo

### The Idea
A feature can work perfectly in a demo and still be **dangerous to merge**. Senior engineers think in diffs — they make changes reviewable, focused, and safe to undo.

### The Junior Way — One Giant PR
```
PR: feat: update billing flow
  - refactor invoice service
  - rename payment fields
  - update refund logic
  - change dashboard UI
  - add new webhook handler
  - modify retry behavior
  - fix customer status bug
  - update tests

👆 This is not a PR. This is a hostage note.
   Bugs hide in the noise. Rollbacks become scary.
```

### ✅ The Senior Way — Small Focused PRs
```
PR 1: Rename payment fields (no behavior changes)
PR 2: Add refund eligibility helper + tests
PR 3: Wire refund eligibility into billing flow
PR 4: Update dashboard UI to show refund reason
PR 5: Add webhook retry behavior

Each PR tells a clear story.
   Easy to review. Easy to roll back. Easy to trust.
```

### The Mental Model
```
❌ Mixing refactor + behavior change = reviewers can't tell what changed
✅ Refactor-only PR  →  Behavior-change PR  →  UI update PR

During an incident:
  Giant diff  = nobody knows what changed
  Small diff  = team can isolate the problem in minutes
```

### Key Takeaway
> Code is not done when it works on your machine.  
> It's done when the change is **understandable, reviewable, testable, and safe to undo**.

---

## The Pattern Under All Patterns

| Pattern | What it reduces |
|---|---|
| Return early | Cognitive load from deep nesting |
| Business names | Time spent reverse-engineering intent |
| External boundaries | Blast radius of third-party changes |
| Invalid state modeling | Bugs hiding until runtime |
| Separate decisions | Test friction from side effects |
| Useful errors | Time lost during incidents |
| Reviewable diffs | Risk of every deployment |

> Senior engineers are not trying to look smart.  
> They are trying to make **the next change less stupid**.  
>
> Good code is not code that shows how much you know.  
> **Good code gives the next developer fewer reasons to guess.**

---
*Content by @codewithboi*

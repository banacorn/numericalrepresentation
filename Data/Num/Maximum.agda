module Data.Num.Maximum where

open import Data.Num.Core
open import Data.Num.Bounded

open import Data.Nat
open import Data.Nat.Properties
open import Data.Nat.Properties.Simple
open import Data.Nat.Properties.Extra

open import Data.Fin as Fin
    using (Fin; fromℕ≤; inject≤)
    renaming (zero to z; suc to s)

open import Data.Fin.Properties using (toℕ-fromℕ≤; bounded)
open import Data.Product
open import Data.Empty using (⊥)
open import Data.Unit using (⊤; tt)

open import Function
open import Relation.Nullary.Decidable
open import Relation.Nullary
open import Relation.Nullary.Negation
open import Relation.Binary
open import Relation.Binary.PropositionalEquality

open ≡-Reasoning
open ≤-Reasoning renaming (begin_ to start_; _∎ to _□; _≡⟨_⟩_ to _≈⟨_⟩_)
open DecTotalOrder decTotalOrder using (reflexive) renaming (refl to ≤-refl)

------------------------------------------------------------------------
--

-- data MaximumCond : ∀ {b} {d} {o} → Num b d o → Set where
--     ≡Bound : ∀ {b d o} (xs : Num b d o) → MaximumCond xs
--
-- data NonMaximumCond : ∀ {b} {d} {o} → Num b d o → Set where
--

Maximum?-lemma-1 : ∀ {b d o}
    → (xs : Num b d o)
    → (max : Num b d o)
    → Maximum max
    → toℕ max ≢ toℕ xs
    → Maximum xs
    → ⊥
Maximum?-lemma-1 xs max claim p xs-be-maximum
    = contradiction ⟦xs⟧≥⟦max⟧ ⟦xs⟧≱⟦max⟧
    where   ⟦xs⟧≥⟦max⟧ : toℕ xs ≥ toℕ max
            ⟦xs⟧≥⟦max⟧ = xs-be-maximum max
            ⟦xs⟧≱⟦max⟧ : toℕ xs ≱ toℕ max
            ⟦xs⟧≱⟦max⟧ = <⇒≱ $ ≤∧≢⇒< (claim xs) (λ x → p (sym x))

Maximum? : ∀ {b d o}
    → (xs : Num b d o)
    → Dec (Maximum xs)
Maximum? {b} {d} {o} xs with boundedView b d o
Maximum? xs | IsBounded cond with BoundedCond⇒Bounded cond
Maximum? xs | IsBounded cond | max , claim with toℕ max ≟ toℕ xs
Maximum? xs | IsBounded cond | max , claim | yes p rewrite p = yes claim
Maximum? xs | IsBounded cond | max , claim | no ¬p = no (Maximum?-lemma-1 xs max claim ¬p)
Maximum? xs | IsntBounded cond = no (¬Bounded⇒¬Maximum (NonBoundedCond⇒¬Bounded cond) xs)
--

next-number-lemma-2 : ∀ {b}
    → (xs : Num (suc b) 1 0)
    → ¬ (Maximum xs)
    → Num (suc b) 1 0
next-number-lemma-2 {b} xs ¬max = contradiction max ¬max
    where   max : Maximum xs
            max ys = HasOnly:0-lemma (suc b) xs ys

next-number-lemma-1 : ∀ {d o}
    → (x : Digit (suc d))
    → (xs : Num 0 (suc d) o)
    → (¬Maximum : ¬ (Maximum (x ∷ xs)))
    → (greatest : Greatest x)
    → Num 0 (suc d) o
next-number-lemma-1 {d} {o} x xs ¬max greatest = contradiction max ¬max
    where   max : Maximum (x ∷ xs)
            max ys = Base≡0-lemma x xs greatest ys

-- begin
--     {!   !}
-- ≡⟨ {!   !} ⟩
--     {!   !}
-- ≡⟨ {!   !} ⟩
--     {!   !}
-- ≡⟨ {!   !} ⟩
--     {!   !}
-- ≡⟨ {!   !} ⟩
--     {!   !}
-- ∎

-- start
--     {!   !}
-- ≤⟨ {!   !} ⟩
--     {!   !}
-- ≤⟨ {!   !} ⟩
--     {!   !}
-- ≤⟨ {!   !} ⟩
--     {!   !}
-- □


next-number-lemma-3 : ∀ {b d o}
    → (x : Digit (suc d))
    → (xs : Num (suc b) (suc d) o)
    → (¬Maximum : ¬ (Maximum (x ∷ xs)))
    → (greatest : Greatest x)
    → suc d + o ≥ 2
    → Maximum xs
    → ⊥
next-number-lemma-3 {b} {d} {o} x xs ¬max greatest d+o≥2 claim = contradiction p ¬p
    where   p : toℕ xs ≥ toℕ (x ∷ xs)
            p = claim (x ∷ xs)
            ¬p : toℕ xs ≱ toℕ (x ∷ xs)
            ¬p = <⇒≱ $
                start
                    suc (toℕ xs)
                ≤⟨ reflexive (cong suc (sym (*-right-identity (toℕ xs)))) ⟩
                    suc (toℕ xs * suc zero)
                ≤⟨ s≤s (n*-mono (toℕ xs) (s≤s z≤n)) ⟩
                    suc (toℕ xs * suc b)
                ≤⟨ +n-mono (toℕ xs * suc b) (≤-pred d+o≥2) ⟩
                    d + o + toℕ xs * suc b
                ≤⟨ reflexive (cong (λ w → w + toℕ xs * suc b) (sym (toℕ-greatest x greatest))) ⟩
                    Digit-toℕ x o + toℕ xs * suc b
                □


next-number-lemma-4 : ∀ d o
    → (¬Maximum : ¬ (Maximum {0} {suc d} {o} ∙))
    → 1 > d + o
    → Num 0 (suc d) o
next-number-lemma-4 zero zero ¬max (s≤s p) = contradiction max ¬max
    where   max : Maximum {0} {1} {0} ∙
            max ∙ = z≤n
            max (z ∷ ys) = reflexive (*-right-zero (toℕ ys))
            max (s () ∷ ys)
next-number-lemma-4 zero (suc o) ¬max (s≤s ())
next-number-lemma-4 (suc d) o ¬max (s≤s ())


next-number : ∀ {b d o}
    → (xs : Num b d o)
    → ¬ (Maximum xs)
    → Num b d o
next-number {b} {d} {o} xs ¬max with boundedView b d o

next-number ∙         ¬max | IsBounded (Base≡0 d o)     with 1 ≤? d + o
next-number ∙         ¬max | IsBounded (Base≡0 zero zero) | yes ()
next-number ∙         ¬max | IsBounded (Base≡0 (suc d) zero) | yes p = s z ∷ ∙
next-number ∙         ¬max | IsBounded (Base≡0 d (suc o)) | yes p = z ∷ ∙
next-number ∙         ¬max | IsBounded (Base≡0 d o) | no ¬p = next-number-lemma-4 d o ¬max (≰⇒> ¬p)
next-number ∙         ¬max | IsBounded (HasNoDigit b o) = contradiction (HasNoDigit-lemma b o) ¬max
next-number ∙         ¬max | IsBounded (HasOnly:0 b)    = next-number-lemma-2 ∙ ¬max
next-number ∙         ¬max | IsntBounded (Digit+Offset≥2 b d o d+o≥2)
    = z ∷ ∙
next-number (x  ∷ xs) ¬max | cond with Greatest? x
next-number (x  ∷ xs) ¬max | IsBounded (Base≡0 d o)     | yes greatest = next-number-lemma-1 {d} {o} x xs ¬max greatest
next-number (() ∷ xs) ¬max | IsBounded (HasNoDigit b o) | yes greatest
next-number (x  ∷ xs) ¬max | IsBounded (HasOnly:0 b)    | yes greatest = next-number-lemma-2 (x ∷ xs) ¬max
next-number (x  ∷ xs) ¬max | IsntBounded (Digit+Offset≥2 b d o d+o≥2) | yes greatest
    = z ∷ next-number xs (next-number-lemma-3 x xs ¬max greatest d+o≥2)
next-number (x  ∷ xs) ¬max | cond | no ¬greatest = digit+1 x ¬greatest ∷ xs

next-number-is-greater : ∀ {b d o}
    → (xs : Num b d o)
    → (¬max : ¬ (Maximum xs))
    → toℕ (next-number xs ¬max) > toℕ xs
next-number-is-greater {b} {d} {o} xs ¬max with boundedView b d o
next-number-is-greater ∙ ¬max | IsBounded (Base≡0 d o) with 1 ≤? d + o
next-number-is-greater ∙ ¬max | IsBounded (Base≡0 zero zero) | yes ()
next-number-is-greater ∙ ¬max | IsBounded (Base≡0 (suc d) zero) | yes p = s≤s z≤n
next-number-is-greater ∙ ¬max | IsBounded (Base≡0 d (suc o)) | yes p = {!   !}
next-number-is-greater ∙ ¬max | IsBounded (Base≡0 d o) | no ¬p = {!   !}
next-number-is-greater ∙ ¬max | IsBounded (HasNoDigit b o) = {!   !}
next-number-is-greater ∙ ¬max | IsBounded (HasOnly:0 b) = {!   !}
next-number-is-greater ∙ ¬max | IsntBounded cond = {!   !}
next-number-is-greater (x ∷ xs) ¬max | cond = {!   !}

-- begin
--     {!   !}
-- ≡⟨ {!   !} ⟩
--     {!   !}
-- ≡⟨ {!   !} ⟩
--     {!   !}
-- ≡⟨ {!   !} ⟩
--     {!   !}
-- ≡⟨ {!   !} ⟩
--     {!   !}
-- ∎

-- start
--     {!   !}
-- ≤⟨ {!   !} ⟩
--     {!   !}
-- ≤⟨ {!   !} ⟩
--     {!   !}
-- ≤⟨ {!   !} ⟩
--     {!   !}
-- □

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

Maximum?-lemma-1 : ∀ {b d o}
    → (x : Digit d) (xs : Num b d o)
    → (m : Digit d) (max : Num b d o)
    → Maximum m max
    → ⟦ m ∷ max ⟧ ≢ ⟦ x ∷ xs ⟧
    → ¬ (Maximum x xs)
Maximum?-lemma-1 x xs m max claim p xs-be-maximum
    = contradiction ⟦x∷xs⟧≥⟦m∷max⟧ ⟦x∷xs⟧≱⟦m∷max⟧
    where   ⟦x∷xs⟧≥⟦m∷max⟧ : ⟦ x ∷ xs ⟧ ≥ ⟦ m ∷ max ⟧
            ⟦x∷xs⟧≥⟦m∷max⟧ = xs-be-maximum m max
            ⟦x∷xs⟧≱⟦m∷max⟧ : ⟦ x ∷ xs ⟧ ≱ ⟦ m ∷ max ⟧
            ⟦x∷xs⟧≱⟦m∷max⟧ = <⇒≱ $ ≤∧≢⇒< (claim x xs) (λ x → p (sym x))

Maximum? : ∀ {b d o}
    → (x : Digit d) (xs : Num b d o)
    → Dec (Maximum x xs)
Maximum? {b} {d} {o} x xs with boundedView b d o
Maximum? x xs | IsBounded cond with BoundedCond⇒Bounded cond
Maximum? x xs | IsBounded cond | m , max , claim with ⟦ m ∷ max ⟧ ≟ ⟦ x ∷ xs ⟧
Maximum? x xs | IsBounded cond | m , max , claim | yes p rewrite p = yes claim
Maximum? x xs | IsBounded cond | m , max , claim | no ¬p = no (Maximum?-lemma-1 x xs m max claim ¬p)
Maximum? x xs | IsntBounded cond = no (¬Bounded⇒¬Maximum (NonBoundedCond⇒¬Bounded cond) x xs)


data Base≡0-View : ℕ → ℕ → Set where
    HasOnly0 :                                  Base≡0-View 0 0
    Others : ∀ {d o} → (bound : d + o ≥ 1 ⊔ o) → Base≡0-View d o

Base≡0-view : ∀ d o → Base≡0-View d o
Base≡0-view zero    zero     = HasOnly0
Base≡0-view zero    (suc o)  = Others (s≤s ≤-refl)
Base≡0-view (suc d) zero     = Others (s≤s z≤n)
Base≡0-view (suc d) (suc o)  = Others (m≤n+m (suc o) (suc d))

next-number-Base≡0-lemma-1 : ∀ d o
    → (x : Digit (suc d)) (xs : Num 0 (suc d) o)
    → 1 > d + o
    → Maximum {0} {suc d} {o} x xs
next-number-Base≡0-lemma-1 zero    zero    x xs p        y ys = HasOnly0-Maximum zero x xs y ys
next-number-Base≡0-lemma-1 zero    (suc o) x xs (s≤s ()) _ _
next-number-Base≡0-lemma-1 (suc d) o       x xs (s≤s ()) _ _

next-number-Base≡0 : ∀ {d o}
    → (x : Digit (suc d)) (xs : Num 0 (suc d) o)
    → ¬ (Maximum x xs)
    → Num 0 (suc d) o
next-number-Base≡0 {d} {o} x xs ¬max with Base≡0-view d o
next-number-Base≡0         x xs ¬max | HasOnly0     = contradiction (next-number-Base≡0-lemma-1 zero zero x xs (s≤s z≤n)) ¬max
next-number-Base≡0 {d} {o} x  ∙ ¬max | Others bound = Digit-fromℕ {d} (1 ⊔ o) o bound ∷ ∙
next-number-Base≡0 x (x' ∷ xs)  ¬max | Others bound with Greatest? x
next-number-Base≡0 x (x' ∷ xs)  ¬max | Others bound | yes greatest = contradiction (Base≡0-lemma x (x' ∷ xs) greatest) ¬max
next-number-Base≡0 x (x' ∷ xs)  ¬max | Others bound | no ¬greatest = digit+1 x ¬greatest ∷ x' ∷ xs

next-number-HasOnly0 : ∀ {b}
    → (x : Digit 1) (xs : Num (suc b) 1 0)
    → ¬ (Maximum x xs)
    → Num (suc b) 1 0
next-number-HasOnly0 {b} x xs ¬max = contradiction (HasOnly0-Maximum (suc b) x xs) ¬max

next-number-Digit+Offset≥2-lemma-1 : ∀ m n → 2 ≤ suc m + n → m + n ≥ 1 ⊔ n
next-number-Digit+Offset≥2-lemma-1 m zero    q = ≤-pred q
next-number-Digit+Offset≥2-lemma-1 m (suc n) q = m≤n+m (suc n) m

-- next-number-Digit+Offset≥2-lemma-2 : ∀ {b d o}
--     → (x : Digit (suc d))
--     → (x' : Digit (suc d)) (xs : Num (suc b) (suc d) o)
--     → (¬Maximum : ¬ (Maximum x (x' ∷ xs)))
--     → (greatest : Greatest x)
--     → suc d + o ≥ 2
--     → ¬ (Maximum x' xs)
-- next-number-Digit+Offset≥2-lemma-2 {b} {d} {o} x x' xs ¬max greatest d+o≥2 claim = contradiction p {! ¬p  !}
--     where   p : ⟦ x' ∷ xs ⟧ ≥ ⟦ x ∷ (x' ∷ xs) ⟧
--             p = claim x (x' ∷ xs)
--             ¬p : ⟦ x' ∷ xs ⟧ ≱ ⟦ x ∷ (x' ∷ xs) ⟧
--             ¬p = <⇒≱ $
--                 start
--                     suc ⟦ x' ∷ xs ⟧
--                 ≈⟨ cong suc (sym (*-right-identity ⟦ x' ∷ xs ⟧)) ⟩
--                     suc (⟦ x' ∷ xs ⟧ * 1)
--                 ≤⟨ s≤s (n*-mono ⟦ x' ∷ xs ⟧ (s≤s z≤n)) ⟩
--                     suc (⟦ x' ∷ xs ⟧ * suc b)
--                 ≤⟨ +n-mono (⟦ x' ∷ xs ⟧ * suc b) (≤-pred d+o≥2) ⟩
--                     d + o + ⟦ x' ∷ xs ⟧ * suc b
--                 ≈⟨ cong (λ w → w + ⟦ x' ∷ xs ⟧ * suc b) (sym (toℕ-greatest x greatest)) ⟩
--                     Digit-toℕ x o + ⟦ x' ∷ xs ⟧ * suc b
--                 □
-- --
--

mutual

    next-number-¬Maximum : ∀ {b d o}
        → (x : Digit (suc d)) (xs : Num (suc b) (suc d) o)
        → (d+o≥2 : 2 ≤ suc (d + o))
        → ¬ Maximum x xs
    next-number-¬Maximum {b} {d} {o} x xs d+o≥2 = ¬Bounded⇒¬Maximum (Digit+Offset≥2-¬Bounded-lemma b d o (≤-pred d+o≥2)) x xs
    --
    -- -- the gap
    -- Gapped : ∀ {b d o}
    --     → (this : Num (suc b) (suc d) o) → ¬ (Null this)
    --     → (next : Num (suc b) (suc d) o) → ¬ (Null next)
    --     → Set
    -- Gapped {b} {d} this p next q = suc d ≤ ((⟦ this ⟧ p) ∸ (⟦ next ⟧ q)) * suc b



    Gapped : ∀ {b d o}
        → (x : Digit (suc d)) (xs : Num (suc b) (suc d) o)
        → (d+o≥2 : 2 ≤ suc (d + o))
        → Set
    Gapped x ∙ d+o≥2 = {!   !}
    Gapped x (x' ∷ xs) d+o≥2 = {!   !}

    -- Gapped : ∀ {b d o}
    --     → (x : Digit (suc d)) (xs : Num (suc b) (suc d) o)
    --     → (d+o≥2 : 2 ≤ suc (d + o))
    --     → Set
    -- Gapped {b} {d} {o} x xs d+o≥2 =
    --     let
    --         ¬max = next-number-¬Maximum x xs d+o≥2
    --         ¬null = next-number-d+o≥2-¬Null x xs ¬max d+o≥2
    --         next-xs-toℕ = ⟦ next-number-d+o≥2 x xs ¬max d+o≥2 ⟧ ¬null
    --     in
    --         suc d ≤ (next-xs-toℕ ∸ ⟦ x ∷ xs ⟧) * suc b
    --
    -- Gapped? : ∀ {b d o}
    --     → (x : Digit (suc d)) (xs : Num (suc b) (suc d) o)
    --     → (d+o≥2 : 2 ≤ suc (d + o))
    --     → Dec (Gapped' x xs d+o≥2)
    -- Gapped? {b} {d} {o} x xs d+o≥2 =
    --     let
    --         ¬max = next-number-¬Maximum x xs d+o≥2
    --         ¬null = next-number-d+o≥2-¬Null x xs ¬max d+o≥2
    --         next-xs-toℕ = ⟦ next-number-d+o≥2 x xs ¬max d+o≥2 ⟧ ¬null
    --     in
    --         suc d ≤? (next-xs-toℕ ∸ ⟦ x ∷ xs ⟧) * suc b

    -- the actual function
    next-number-d+o≥2 : ∀ {b d o}
        → (x : Digit (suc d)) (xs : Num (suc b) (suc d) o)
        → ¬ (Maximum x xs)
        → (d+o≥2 : 2 ≤ suc (d + o))
        → Num (suc b) (suc d) o
    next-number-d+o≥2 {b} {d} {o} x xs ¬max prop with Greatest? x
    next-number-d+o≥2 {b} {d} {o} x ∙         ¬max prop | yes greatest
        with suc d ≤? (1 ⊔ o) * suc b
    next-number-d+o≥2 {b} {d} {o} x ∙ ¬max prop | yes greatest | yes gapped =
        z ∷ Digit-fromℕ {d} (1 ⊔ o) o (next-number-Digit+Offset≥2-lemma-1 d o prop) ∷ ∙
    next-number-d+o≥2 {b} {d} {o} x ∙ ¬max prop | yes greatest | no ¬gapped =
        let prop2 : (1 ⊔ o) * suc b > 0
            prop2 = m≤m⊔n 1 o *-mono s≤s z≤n
        in  digit+1-n x greatest ((1 ⊔ o) * suc b) prop2 ∷ z ∷ ∙
    next-number-d+o≥2 {b} {d} {o} x (x' ∷ xs) ¬max prop | yes greatest = {!   !}
    next-number-d+o≥2 {b} {d} {o} x xs        ¬max prop | no ¬greatest = {!   !}
    -- next-number-d+o≥2 {b} {d} {o} x ∙ ¬max prop =  {!   !} -- Digit-fromℕ {d} (1 ⊔ o) o (next-number-Digit+Offset≥2-lemma-1 d o prop) ∷ ∙
    -- next-number-d+o≥2 x (x' ∷ xs) ¬max prop with Greatest? x
    -- next-number-d+o≥2 x (x' ∷ xs) ¬max prop | yes greatest with Gapped? x' xs prop
    -- next-number-d+o≥2 x (x' ∷ xs) ¬max prop | yes greatest | yes gapped =
    --     let
    --         ¬max = next-number-¬Maximum x xs prop
    --     in
    --     z ∷ next-number-d+o≥2 x xs ¬max prop
    -- next-number-d+o≥2 x (x' ∷ xs) ¬max prop | yes greatest | no ¬gapped = {!   !}
    -- next-number-d+o≥2 x (x' ∷ xs) ¬max prop | no ¬greatest = {!   !}

    -- properties of the actual function
    next-number-d+o≥2-¬Null : ∀ {b d o}
        → (x : Digit (suc d)) (xs : Num (suc b) (suc d) o)
        → (¬max : ¬ (Maximum x xs))
        → (d+o≥2 : 2 ≤ suc (d + o))
        → ¬ Null (next-number-d+o≥2 x xs ¬max d+o≥2)
    -- next-number-d+o≥2-¬Null {b} {d} {o} x xs ¬max prop = {!   !}
    next-number-d+o≥2-¬Null {b} {d} {o} x xs ¬max prop with Greatest? x
    next-number-d+o≥2-¬Null {b} {d} {o} x ∙         ¬max prop | yes greatest
        with suc d ≤? (1 ⊔ o) * suc b
    next-number-d+o≥2-¬Null {b} {d} {o} x ∙ ¬max prop | yes greatest | yes gapped = λ bot → bot
    next-number-d+o≥2-¬Null {b} {d} {o} x ∙ ¬max prop | yes greatest | no ¬gapped = λ bot → bot
    next-number-d+o≥2-¬Null {b} {d} {o} x (x' ∷ xs) ¬max prop | yes greatest = {!   !}
    next-number-d+o≥2-¬Null {b} {d} {o} x xs        ¬max prop | no ¬greatest = {!   !}


    -- next-number-d+o≥2-¬Null {b} {d} {o} x ∙ ¬max prop ()
    -- next-number-d+o≥2-¬Null x (x' ∷ xs) ¬max prop with Greatest? x
    -- next-number-d+o≥2-¬Null x (x' ∷ xs) ¬max prop | yes greatest with Gapped? x' xs prop
    -- next-number-d+o≥2-¬Null x (x' ∷ xs) ¬max prop | yes greatest | yes gapped = λ bot → bot
    -- next-number-d+o≥2-¬Null x (x' ∷ xs) ¬max prop | yes greatest | no ¬gapped = {!   !}
    -- next-number-d+o≥2-¬Null x (x' ∷ xs) ¬max prop | no ¬greatest = {!   !}

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

    next-number-d+o≥2-is-greater : ∀ {b d o}
        → (x : Digit (suc d)) (xs : Num (suc b) (suc d) o)
        → (¬max : ¬ (Maximum x xs))
        → (d+o≥2 : 2 ≤ suc (d + o))
        → ⟦ next-number-d+o≥2 x xs ¬max d+o≥2 ⟧ next-number-d+o≥2-¬Null x xs ¬max d+o≥2 > ⟦ x ∷ xs ⟧
    -- next-number-d+o≥2-is-greater {b} {d} {o} x xs ¬max prop = {!   !}
    next-number-d+o≥2-is-greater {b} {d} {o} x xs ¬max prop with Greatest? x
    next-number-d+o≥2-is-greater {b} {d} {o} x ∙         ¬max prop | yes greatest
        with suc d ≤? (1 ⊔ o) * suc b
    next-number-d+o≥2-is-greater {b} {d} {o} x ∙ ¬max prop | yes greatest | yes gapped =
        let
            lower-bound : o ≤ 1 ⊔ o
            lower-bound =
                start
                    o
                ≤⟨ m≤m⊔n o (suc zero) ⟩
                    o ⊔ suc zero
                ≈⟨ ⊔-comm o (suc zero) ⟩
                    suc zero ⊔ o
                □
            upper-bound : d + o ≥ 1 ⊔ o
            upper-bound = next-number-Digit+Offset≥2-lemma-1 d o prop
        in start
            suc (Fin.toℕ x + o + zero)
        ≈⟨ cong (λ w → w + o + 0) greatest ⟩
            (suc d + o) + zero
        ≈⟨ +-right-identity (suc d + o) ⟩
            suc (d + o)
        ≈⟨ +-comm (suc d) o ⟩
            o + suc d
        ≤⟨ n+-mono o gapped ⟩
            o + (suc zero ⊔ o) * suc b
        ≈⟨ cong (λ w → o + w * suc b) (sym (+-right-identity (1 ⊔ o))) ⟩
            o + (suc zero ⊔ o + zero) * suc b
        ≈⟨ cong (λ w → o + (w + 0) * suc b) (sym (Digit-toℕ-fromℕ {d} {o} (1 ⊔ o) upper-bound lower-bound)) ⟩
            o + (Digit-toℕ (Digit-fromℕ {d} (1 ⊔ o) o (next-number-Digit+Offset≥2-lemma-1 d o prop)) o + zero) * suc b
        □
    next-number-d+o≥2-is-greater {b} {d} {o} x ∙ ¬max prop | yes greatest | no ¬gapped =
        let
            lower-bound : (suc zero ⊔ o) * suc b ≤ suc d
            lower-bound = ≤-pred $ ≤-step $ ≰⇒> ¬gapped
            upper-bound : 1 ≤ (suc zero ⊔ o) * suc b
            upper-bound = m≤m⊔n (suc zero) o *-mono s≤s z≤n
        in start
            suc (Fin.toℕ x + o + zero)
        ≤⟨ {!   !} ⟩
            {!   !}
        ≤⟨ {!   !} ⟩
            {!   !}
        ≤⟨ {!   !} ⟩
            {!   !}
        ≤⟨ {!   !} ⟩
            {!   !}
        ≤⟨ {!   !} ⟩
            {!   !}
        ≤⟨ {!   !} ⟩
            {!   !}
        ≤⟨ {!   !} ⟩
            {!   !}
        ≤⟨ {!   !} ⟩
            {!   !}
        ≤⟨ {!   !} ⟩
            {!   !}
        ≤⟨ {!   !} ⟩
            {!   !}
        ≤⟨ {!   !} ⟩
            {!   !}
        ≈⟨ {!    !} ⟩
            suc (Fin.toℕ x + o) ∸ (suc zero ⊔ o) * suc b + (o + zero) * suc b
        ≈⟨ cong (λ w → w + (o + zero) * suc b) (sym (Digit-toℕ-digit+1-n x greatest ((suc zero ⊔ o) * suc b) upper-bound lower-bound)) ⟩
            Digit-toℕ (digit+1-n x greatest ((1 ⊔ o) * suc b) (m≤m⊔n 1 o *-mono s≤s z≤n)) o + (o + zero) * suc b
        □
    next-number-d+o≥2-is-greater {b} {d} {o} x (x' ∷ xs) ¬max prop | yes greatest = {!   !}
    next-number-d+o≥2-is-greater {b} {d} {o} x xs        ¬max prop | no ¬greatest = {!   !}

    -- next-number-d+o≥2-is-greater {b} {d} {o} x ∙ ¬max prop =
    --     start
    --         suc (Fin.toℕ x + o + zero)
    --     ≤⟨ {!   !} ⟩
    --         {!   !}
    --     ≤⟨ {!   !} ⟩
    --         {!   !}
    --     ≤⟨ {!   !} ⟩
    --         {!   !}
    --     ≤⟨ {!   !} ⟩
    --         {!   !}
    --     ≈⟨ cong (λ w → w + 0) (sym (Digit-toℕ-fromℕ {!   !} {!   !} {!   !})) ⟩
    --         Digit-toℕ (Digit-fromℕ {d} (1 ⊔ o) o (next-number-Digit+Offset≥2-lemma-1 d o prop)) o + zero
    --     □

--         start
--             suc zero
--         ≤⟨ m≤m⊔n (suc zero) o ⟩
--             suc zero ⊔ o
--         ≤⟨ reflexive (sym (+-right-identity (suc zero ⊔ o))) ⟩
--             suc zero ⊔ o + zero
--         ≤⟨ +n-mono 0 (reflexive (sym (Digit-toℕ-fromℕ {d} (suc zero ⊔ o) (next-number-Digit+Offset≥2-lemma-1 d o p) $
--             start
--                 o
--             ≤⟨ m≤m⊔n o (suc zero) ⟩
--                 o ⊔ suc zero
--             ≤⟨ reflexive (⊔-comm o (suc zero)) ⟩
--                 suc zero ⊔ o
--             □)))
--         ⟩
--             Digit-toℕ (Digit-fromℕ {d} (1 ⊔ o) o (next-number-Digit+Offset≥2-lemma-1 d o p)) o + zero
--         □
    -- next-number-d+o≥2-is-greater x (x' ∷ xs) ¬max prop with Greatest? x
    -- next-number-d+o≥2-is-greater x (x' ∷ xs) ¬max prop | yes greatest with Gapped? x' xs prop
    -- next-number-d+o≥2-is-greater x (x' ∷ xs) ¬max prop | yes greatest | yes gapped = {!   !}
    -- next-number-d+o≥2-is-greater x (x' ∷ xs) ¬max prop | yes greatest | no ¬gapped = {!   !}
    -- next-number-d+o≥2-is-greater x (x' ∷ xs) ¬max prop | no ¬greatest = {!   !}







    -- data Digit+Offset≥2-View : (b d o : ℕ) → Digit (suc d) → Num (suc b) (suc d) o → Set where
    --     Digit+Offset≥2-View-Null : ∀ {b d o x xs}
    --         → Digit+Offset≥2-View (suc b) (suc d) o x xs
    --     Digit+Offset≥2-View-Gapped : ∀ {b d o x xs}
    --         → Greatest x
    --         → Greatest x
    --         → Digit+Offset≥2-View (suc b) (suc d) o x xs
    -- Digit+Offset≥2-View-¬Gapped : ∀ {b d o} → Digit+Offset≥2-View (suc b) (suc d) o
    -- Digit+Offset≥2-View-¬Greatest : ∀ {b d o} → Digit+Offset≥2-View (suc b) (suc d) o


    -- HasOnly0 :                                  Base≡0-View 0 0
    -- Others : ∀ {d o} → (bound : d + o ≥ 1 ⊔ o) → Base≡0-View d o

-- Base≡0-view : ∀ d o → Base≡0-View d o
-- Base≡0-view zero    zero     = HasOnly0
-- Base≡0-view zero    (suc o)  = Others (s≤s ≤-refl)
-- Base≡0-view (suc d) zero     = Others (s≤s z≤n)
-- Base≡0-view (suc d) (suc o)  = Others (m≤n+m (suc o) (suc d))
-- mutual

    -- next-number-Digit+Offset≥2 : ∀ {b d o}
    --     → (x : Digit (suc d)) (xs : Num (suc b) (suc d) o)
    --     → ¬ (Maximum x xs)
    --     → (d+o≥2 : 2 ≤ suc (d + o))
    --     → Num (suc b) (suc d) o
    -- -- next-number-Digit+Offset≥2 = {!   !}
    -- next-number-Digit+Offset≥2 {_} {d} {o} x ∙         ¬max d+o≥2 = Digit-fromℕ {d} (1 ⊔ o) o (next-number-Digit+Offset≥2-lemma-1 d o d+o≥2) ∷ ∙
    -- next-number-Digit+Offset≥2 {_} {d} {o} x (x' ∷ xs) ¬max d+o≥2 with Greatest? x
    -- next-number-Digit+Offset≥2 {b} {d} {o} x (x' ∷ xs) ¬max d+o≥2 | yes greatest
    --     with suc d ≤? (⟦ next-number-Digit+Offset≥2 x' xs (¬Bounded⇒¬Maximum (Digit+Offset≥2-¬Bounded-lemma b d o (≤-pred d+o≥2)) x' xs) d+o≥2 ⟧ next-number-Digit+Offset≥2-¬Null x' xs (¬Bounded⇒¬Maximum (Digit+Offset≥2-¬Bounded-lemma b d o (≤-pred d+o≥2)) x' xs) d+o≥2 ∸ ⟦ x' ∷ xs ⟧) * suc b
    -- next-number-Digit+Offset≥2 {b} {d} {o} x (x' ∷ xs) ¬max d+o≥2 | yes greatest | yes gapped
    --     = z ∷ next-number-Digit+Offset≥2 x' xs (¬Bounded⇒¬Maximum (Digit+Offset≥2-¬Bounded-lemma b d o (≤-pred d+o≥2)) x' xs) d+o≥2
    -- next-number-Digit+Offset≥2 {b} {d} {o} x (x' ∷ xs) ¬max d+o≥2 | yes greatest | no ¬gapped =
    --     let
    --         ¬max-xs = ¬Bounded⇒¬Maximum (Digit+Offset≥2-¬Bounded-lemma b d o (≤-pred d+o≥2)) x' xs
    --         next-xs = next-number-Digit+Offset≥2 x' xs ¬max-xs d+o≥2
    --         next-xs-¬Null = next-number-Digit+Offset≥2-¬Null x' xs ¬max-xs d+o≥2
    --         gap = (⟦ next-xs ⟧ next-xs-¬Null ∸ ⟦ x' ∷ xs ⟧) * suc b
    --         gap>0 = (start
    --                 1
    --             ≤⟨ s≤s (reflexive (sym (n∸n≡0 ⟦ x' ∷ xs ⟧))) ⟩
    --                 suc (⟦ x' ∷ xs ⟧ ∸ ⟦ x' ∷ xs ⟧)
    --             ≈⟨ sym (+-∸-assoc 1 {⟦ x' ∷ xs ⟧} ≤-refl) ⟩
    --                 suc (⟦ x' ∷ xs ⟧) ∸ ⟦ x' ∷ xs ⟧
    --             -- ≤⟨ ∸-mono {suc (⟦ x' ∷ xs ⟧)} {⟦ next-xs ⟧ ?} {⟦ x' ∷ xs ⟧} (next-number-is-greater-Digit+Offset≥2 x xs ¬max-xs d+o≥2) ≤-refl ⟩
    --             ≤⟨ ∸-mono {suc (⟦ x' ∷ xs ⟧)} {⟦ next-xs ⟧ next-xs-¬Null} {⟦ x' ∷ xs ⟧} {!   !} ≤-refl ⟩
    --                 ⟦ next-xs ⟧ next-xs-¬Null ∸ ⟦ x' ∷ xs ⟧
    --             □) *-mono (s≤s z≤n)
    --     in
    --     digit+1-n x greatest gap gap>0 ∷ next-xs
    -- next-number-Digit+Offset≥2 {_} {d} {o} x (x' ∷ xs) ¬max p | no ¬greatest = digit+1 x ¬greatest ∷ x' ∷ xs
    --
    -- next-number-Digit+Offset≥2-¬Null :  ∀ {b d o}
    --     → (x : Digit (suc d)) (xs : Num (suc b) (suc d) o)
    --     → (¬max : ¬ (Maximum x xs))
    --     → (d+o≥2 : 2 ≤ suc (d + o))
    --     → ¬ Null (next-number-Digit+Offset≥2 x xs ¬max d+o≥2)
    -- next-number-Digit+Offset≥2-¬Null x ∙ ¬max d+o≥2 ()
    -- next-number-Digit+Offset≥2-¬Null x (x' ∷ xs) ¬max d+o≥2 claim with Greatest? x
    -- next-number-Digit+Offset≥2-¬Null {b} {d} {o} x (x' ∷ xs) ¬max d+o≥2 claim | yes greatest
    --     with suc d ≤? (⟦ next-number-Digit+Offset≥2 x' xs (¬Bounded⇒¬Maximum (Digit+Offset≥2-¬Bounded-lemma b d o (≤-pred d+o≥2)) x' xs) d+o≥2 ⟧ next-number-Digit+Offset≥2-¬Null x' xs (¬Bounded⇒¬Maximum (Digit+Offset≥2-¬Bounded-lemma b d o (≤-pred d+o≥2)) x' xs) d+o≥2 ∸ ⟦ x' ∷ xs ⟧) * suc b
    -- next-number-Digit+Offset≥2-¬Null x (x' ∷ xs) ¬max d+o≥2 ()    | yes greatest | yes gapped
    -- next-number-Digit+Offset≥2-¬Null x (x' ∷ xs) ¬max d+o≥2 claim | yes greatest | no ¬gapped = {!   !}
    -- -- next-number-Digit+Offset≥2-¬Null {b} {d} {o} x (x' ∷ xs) ¬max d+o≥2 claim | yes greatest with next-number-Digit+Offset≥2 x' xs (¬Bounded⇒¬Maximum (Digit+Offset≥2-¬Bounded-lemma b d o (≤-pred d+o≥2)) x' xs) d+o≥2
    -- -- next-number-Digit+Offset≥2-¬Null {b} {d} {o} x (x' ∷ xs) ¬max d+o≥2 claim | yes greatest | ∙ = next-number-Digit+Offset≥2-¬Null x' xs (¬Bounded⇒¬Maximum (Digit+Offset≥2-¬Bounded-lemma b d o (≤-pred d+o≥2)) x' xs) d+o≥2 {! claim  !}
    -- -- next-number-Digit+Offset≥2-¬Null {b} {d} {o} x (x' ∷ xs) ¬max d+o≥2 claim | yes greatest | next-x' ∷ next-xs = {!   !}
    -- next-number-Digit+Offset≥2-¬Null {b} {d} {o} x (x' ∷ xs) ¬max d+o≥2 claim | no ¬greatest = {!   !}
    --
    -- next-number-is-greater-Digit+Offset≥2 : ∀ {b d o}
    --     → (x : Digit (suc d)) (xs : Num (suc b) (suc d) o)
    --     → (¬max : ¬ (Maximum x xs))
    --     → (d+o≥2 : 2 ≤ suc (d + o))
    --     → ⟦ next-number-Digit+Offset≥2 x xs ¬max d+o≥2 ⟧ next-number-Digit+Offset≥2-¬Null x xs ¬max d+o≥2 > ⟦ x ∷ xs ⟧
    -- next-number-is-greater-Digit+Offset≥2 x ∙ ¬max d+o≥2 = {!   !}
    -- next-number-is-greater-Digit+Offset≥2 x (x' ∷ xs) ¬max d+o≥2 = {!   !}

-- mutual
--     next-number-Digit+Offset≥2 : ∀ {b d o}
--         → (xs : Num (suc b) (suc d) o)
--         → ¬ (Maximum xs)
--         → (d+o≥2 : 2 ≤ suc (d + o))
--         → Num (suc b) (suc d) o
--     next-number-Digit+Offset≥2 {_} {d} {o} ∙        ¬max p = Digit-fromℕ {d} (1 ⊔ o) o (next-number-Digit+Offset≥2-lemma-1 d o p) ∷ ∙
--     next-number-Digit+Offset≥2 {_} {d} {o} (x ∷ xs) ¬max p with Greatest? x
--     next-number-Digit+Offset≥2 {b} {d} {o} (x ∷ xs) ¬max p | yes greatest
--         -- see if there's a gap between x∷xs and the next number
--         -- if it's gapped, then jump right to "0 ∷ next-xs"
--         -- else shrink the digit
--         with suc d ≤? (toℕ (next-number-Digit+Offset≥2 xs (next-number-Digit+Offset≥2-lemma-2 x xs ¬max greatest p) p) ∸ toℕ xs) * suc b
--     next-number-Digit+Offset≥2 {b} {d} {o} (x ∷ xs) ¬max p | yes greatest | yes gapped
--         = z ∷ next-number-Digit+Offset≥2 xs (next-number-Digit+Offset≥2-lemma-2 x xs ¬max greatest p) p
--     next-number-Digit+Offset≥2 {b} {d} {o} (x ∷ xs) ¬max p | yes greatest | no ¬gapped =
--         let
--             ¬max-xs = next-number-Digit+Offset≥2-lemma-2 x xs ¬max greatest p
--             next-xs = next-number-Digit+Offset≥2 xs ¬max-xs p
--             gap = (toℕ next-xs ∸ toℕ xs) * suc b
--             gap>0 = (start
--                     1
--                 ≤⟨ s≤s (reflexive (sym (n∸n≡0 (toℕ xs)))) ⟩
--                     suc (toℕ xs ∸ toℕ xs)
--                 ≤⟨ reflexive (sym (+-∸-assoc 1 {toℕ xs} ≤-refl)) ⟩
--                     suc (toℕ xs) ∸ toℕ xs
--                 ≤⟨ ∸-mono {suc (toℕ xs)} {toℕ next-xs} {toℕ xs} (next-number-is-greater-Digit+Offset≥2 xs ¬max-xs p) ≤-refl ⟩
--                     toℕ next-xs ∸ toℕ xs
--                 □) *-mono (s≤s z≤n)
--         in
--         digit+1-n x greatest gap gap>0 ∷ next-xs
--     next-number-Digit+Offset≥2 {_} {d} {o} (x ∷ xs) ¬max p | no ¬greatest = digit+1 x ¬greatest ∷ xs
--
--
--     next-number-is-greater-Digit+Offset≥2 : ∀ {b d o}
--         → (xs : Num (suc b) (suc d) o)
--         → (¬max : ¬ (Maximum xs))
--         → (d+o≥2 : 2 ≤ suc (d + o))
--         → toℕ (next-number-Digit+Offset≥2 xs ¬max d+o≥2) > toℕ xs
--     next-number-is-greater-Digit+Offset≥2 {b} {d} {o}     ∙ ¬max p =
--         start
--             suc zero
--         ≤⟨ m≤m⊔n (suc zero) o ⟩
--             suc zero ⊔ o
--         ≤⟨ reflexive (sym (+-right-identity (suc zero ⊔ o))) ⟩
--             suc zero ⊔ o + zero
--         ≤⟨ +n-mono 0 (reflexive (sym (Digit-toℕ-fromℕ {d} (suc zero ⊔ o) (next-number-Digit+Offset≥2-lemma-1 d o p) $
--             start
--                 o
--             ≤⟨ m≤m⊔n o (suc zero) ⟩
--                 o ⊔ suc zero
--             ≤⟨ reflexive (⊔-comm o (suc zero)) ⟩
--                 suc zero ⊔ o
--             □)))
--         ⟩
--             Digit-toℕ (Digit-fromℕ {d} (1 ⊔ o) o (next-number-Digit+Offset≥2-lemma-1 d o p)) o + zero
--         □
--     next-number-is-greater-Digit+Offset≥2 {b} {d} {o} (x ∷ xs) ¬max p with Greatest? x
--     next-number-is-greater-Digit+Offset≥2 {b} {d} {o} (x ∷ xs) ¬max p | yes greatest
--         with suc d ≤? (toℕ (next-number-Digit+Offset≥2 xs (next-number-Digit+Offset≥2-lemma-2 x xs ¬max greatest p) p) ∸ toℕ xs) * suc b
--     next-number-is-greater-Digit+Offset≥2 {b} {d} {o} (x ∷ xs) ¬max p | yes greatest | yes gapped =
--         let
--             ¬max-xs : ¬ (Maximum xs)
--             ¬max-xs = next-number-Digit+Offset≥2-lemma-2 x xs ¬max greatest p
--
--             next-xs : Num (suc b) (suc d) o
--             next-xs = next-number-Digit+Offset≥2 xs ¬max-xs p
--
--             next-xs>xs : toℕ next-xs > toℕ xs
--             next-xs>xs = next-number-is-greater-Digit+Offset≥2 xs ¬max-xs p
--
--         in
--         start
--             suc ⟦ x ∷ x' ∷ xs ⟧
--         ≤⟨ ≤-refl ⟩
--             suc (Digit-toℕ x o) + toℕ xs * suc b
--         ≤⟨ reflexive (cong (λ w → suc w + toℕ xs * suc b) (toℕ-greatest x greatest)) ⟩
--             suc d + o + toℕ xs * suc b
--         ≤⟨ reflexive (+-assoc (suc d) o (toℕ xs * suc b)) ⟩
--             suc d + (o + toℕ xs * suc b)
--         ≤⟨ reflexive (a+[b+c]≡b+[a+c] (suc d) o (toℕ xs * suc b)) ⟩
--             o + (suc d + toℕ xs * suc b)
--         ≤⟨ ≤-refl ⟩
--             o + (suc d + toℕ xs * suc b)
--         ≤⟨ n+-mono o (+n-mono (toℕ xs * suc b) gapped) ⟩
--             o + ((toℕ next-xs ∸ toℕ xs) * suc b + toℕ xs * suc b)
--         ≤⟨ reflexive (cong (λ w → o + w) (sym (distribʳ-*-+ (suc b) (toℕ next-xs ∸ toℕ xs) (toℕ xs)))) ⟩
--             o + (toℕ next-xs ∸ toℕ xs + toℕ xs) * suc b
--         ≤⟨ reflexive (cong (λ w → o + w * suc b) (m∸n+n≡m (≤-pred $ ≤-step next-xs>xs))) ⟩
--             o + toℕ next-xs * suc b
--         ≤⟨ ≤-refl ⟩
--             toℕ (z ∷ next-xs)
--         □
--     next-number-is-greater-Digit+Offset≥2 {b} {d} {o} (x ∷ xs) ¬max p | yes greatest | no ¬gapped =
--         let
--             ¬max-xs : ¬ (Maximum xs)
--             ¬max-xs = next-number-Digit+Offset≥2-lemma-2 x xs ¬max greatest p
--
--             next-xs : Num (suc b) (suc d) o
--             next-xs = next-number-Digit+Offset≥2 xs (next-number-Digit+Offset≥2-lemma-2 x xs ¬max greatest p) p
--
--             gap : ℕ
--             gap = (toℕ next-xs ∸ toℕ xs) * suc b
--
--             gap>0 : gap > 0
--             gap>0 = (start
--                     1
--                 ≤⟨ s≤s (reflexive (sym (n∸n≡0 (toℕ xs)))) ⟩
--                     suc (toℕ xs ∸ toℕ xs)
--                 ≤⟨ reflexive (sym (+-∸-assoc 1 {toℕ xs} ≤-refl)) ⟩
--                     suc (toℕ xs) ∸ toℕ xs
--                 ≤⟨ ∸-mono {suc (toℕ xs)} {toℕ next-xs} {toℕ xs} (next-number-is-greater-Digit+Offset≥2 xs ¬max-xs p) ≤-refl ⟩
--                     toℕ next-xs ∸ toℕ xs
--                 □) *-mono (s≤s z≤n)
--
--             next-xs>xs : toℕ next-xs > toℕ xs
--             next-xs>xs = next-number-is-greater-Digit+Offset≥2 xs ¬max-xs p
--
--             next-xs-upper-bound : toℕ next-xs * suc b ∸ toℕ xs * suc b ≤ suc (Digit-toℕ x o)
--             next-xs-upper-bound =
--                 start
--                     toℕ next-xs * suc b ∸ toℕ xs * suc b
--                 ≤⟨ reflexive (sym (*-distrib-∸ʳ (suc b) (toℕ next-xs) (toℕ xs))) ⟩
--                     (toℕ next-xs ∸ toℕ xs) * suc b
--                 ≤⟨ ≤-pred $ ≰⇒> ¬gapped ⟩
--                     d
--                 ≤⟨ m≤m+n d (suc o) ⟩
--                     d + suc o
--                 ≤⟨ reflexive (+-suc d o) ⟩
--                     suc (d + o)
--                 ≤⟨ s≤s $ reflexive (sym (toℕ-greatest x greatest)) ⟩
--                     suc (Fin.toℕ x + o)
--                 □
--             next-xs-lower-bound : toℕ xs * suc b ≤ toℕ next-xs * suc b
--             next-xs-lower-bound = *n-mono (suc b) (≤-pred (≤-step (next-number-is-greater-Digit+Offset≥2 xs ¬max-xs p)))
--
--         in reflexive $ sym $ begin
--                 toℕ (digit+1-n x greatest gap gap>0  ∷ next-xs)
--             ≡⟨ refl ⟩
--                 Digit-toℕ (digit+1-n x greatest gap gap>0) o + toℕ next-xs * suc b
--             ≡⟨ cong (λ w → w + toℕ next-xs * suc b) (Digit-toℕ-digit+1-n x greatest gap gap>0 (≤-pred $ ≤-step $ ≰⇒> ¬gapped)) ⟩
--                 suc (Digit-toℕ x o) ∸ (toℕ next-xs ∸ toℕ xs) * suc b + toℕ next-xs * suc b
--             ≡⟨ cong (λ w → suc (Digit-toℕ x o) ∸ w + toℕ next-xs * suc b) (*-distrib-∸ʳ (suc b) (toℕ next-xs) (toℕ xs)) ⟩
--                 suc (Digit-toℕ x o) ∸ (toℕ next-xs * suc b ∸ toℕ xs * suc b) + toℕ next-xs * suc b
--             ≡⟨ m∸[o∸n]+o≡m+n (suc (Digit-toℕ x o)) (toℕ xs * suc b) (toℕ next-xs * suc b) next-xs-lower-bound next-xs-upper-bound ⟩
--                 suc (toℕ (x ∷ xs))
--             ∎
--     next-number-is-greater-Digit+Offset≥2 {b} {d} {o} (x ∷ xs) ¬max p | no ¬greatest
--         = +n-mono (toℕ xs * suc b) (reflexive (sym (Digit-toℕ-digit+1 x ¬greatest)))
--

-- next-number : ∀ {b d o}
--     → (x : Digit d) (xs : Num b d o)
--     → ¬ (Maximum x xs)
--     → Num b d o
-- next-number {b} {d} {o} x xs ¬max with boundedView b d o
-- next-number x xs ¬max | IsBounded (Base≡0 d o) = next-number-Base≡0 x xs ¬max
-- next-number x xs ¬max | IsBounded (HasOnly0 b) = next-number-HasOnly0 x xs ¬max
-- next-number x xs ¬max | IsntBounded (Digit+Offset≥2 b d o d+o≥2) = next-number-Digit+Offset≥2 x xs ¬max d+o≥2
-- next-number x xs ¬max | IsntBounded (HasNoDigit b o) = {!   !}
-- next-number x xs ¬max | IsBounded (Base≡0 d o) = next-number-Base≡0 x xs ¬max
-- next-number x xs ¬max | IsBounded (HasOnly0 b) = next-number-HasOnly0 x xs ¬max
-- next-number x xs ¬max | IsntBounded (Digit+Offset≥2 b d o d+o≥2) = {!   !}
-- next-number xs ¬max | IsBounded (Base≡0 d o)    = next-number-Base≡0 xs ¬max
-- -- next-number xs ¬max | IsBounded (HasNoDigit b o) = next-number-HasNoDigit xs ¬max
-- next-number xs ¬max | IsBounded (HasOnly0 b) = next-number-HasOnly0 xs ¬max
-- next-number xs ¬max | IsntBounded (Digit+Offset≥2 b d o d+o≥2) = next-number-Digit+Offset≥2 xs ¬max d+o≥2

-- next-number-is-greater-Base≡0 : ∀ {d o}
--     → (xs : Num 0 (suc d) o)
--     → (¬max : ¬ (Maximum xs))
--     → toℕ (next-number-Base≡0 xs ¬max) > toℕ xs
-- next-number-is-greater-Base≡0 {d} {o} xs ¬max with Base≡0-view d o
-- next-number-is-greater-Base≡0 xs ¬max | HasOnly0 = contradiction (next-number-Base≡0-lemma-1 zero zero xs (s≤s z≤n)) ¬max
-- next-number-is-greater-Base≡0 {d} {o} ∙ ¬max | Others bound =
--     start
--         1
--     ≤⟨ m≤m⊔n 1 o ⟩
--         1 ⊔ o
--     ≤⟨ reflexive $
--         begin
--             1 ⊔ o
--         ≡⟨ sym (+-right-identity (1 ⊔ o)) ⟩
--             1 ⊔ o + 0
--         ≡⟨ cong (λ x → x + 0) (sym (Digit-toℕ-fromℕ {d} {o} (suc zero ⊔ o) bound $ start
--                 o
--             ≤⟨ m≤m⊔n o 1 ⟩
--                 o ⊔ 1
--             ≤⟨ reflexive (⊔-comm o 1) ⟩
--                 1 ⊔ o
--             □))
--         ⟩
--             Digit-toℕ {suc d} (Digit-fromℕ {d} (1 ⊔ o) o bound) o + 0
--         ∎
--     ⟩
--         Digit-toℕ {suc d} (Digit-fromℕ {d} (1 ⊔ o) o bound) o + 0
--     □
-- next-number-is-greater-Base≡0 (x ∷ xs) ¬max | Others bound with Greatest? x
-- next-number-is-greater-Base≡0 (x ∷ xs) ¬max | Others bound | yes greatest = contradiction (Base≡0-lemma x xs greatest) ¬max
-- next-number-is-greater-Base≡0 (x ∷ xs) ¬max | Others bound | no ¬greatest = ∷ns-mono-strict x (digit+1 x ¬greatest) xs xs refl (reflexive (sym (Digit-toℕ-digit+1 x ¬greatest)))
--
--
-- next-number-is-greater-HasNoDigit : ∀ {b o}
--     → (xs : Num b 0 o)
--     → (¬max : ¬ (Maximum xs))
--     → toℕ (next-number-HasNoDigit xs ¬max) > toℕ xs
-- next-number-is-greater-HasNoDigit {b} {o} ∙         ¬max = contradiction (HasNoDigit-lemma b o) ¬max
-- next-number-is-greater-HasNoDigit         (() ∷ xs) ¬max
--
-- next-number-is-greater-HasOnly0 : ∀ {b}
--     → (xs : Num (suc b) 1 0)
--     → (¬max : ¬ (Maximum xs))
--     → toℕ (next-number-HasOnly0 xs ¬max) > toℕ xs
-- next-number-is-greater-HasOnly0 {b} xs ¬max = contradiction (HasOnly0-Maximum (suc b) xs) ¬max
--
--
-- next-number-is-greater : ∀ {b d o}
--     → (xs : Num b d o)
--     → (¬max : ¬ (Maximum xs))
--     → toℕ (next-number xs ¬max) > toℕ xs
-- next-number-is-greater {b} {d} {o} xs ¬max with boundedView b d o
-- next-number-is-greater xs ¬max | IsBounded (Base≡0 d o) = next-number-is-greater-Base≡0 xs ¬max
-- next-number-is-greater xs ¬max | IsBounded (HasNoDigit b o) = next-number-is-greater-HasNoDigit xs ¬max
-- next-number-is-greater xs ¬max | IsBounded (HasOnly0 b) = next-number-is-greater-HasOnly0 xs ¬max
-- next-number-is-greater xs ¬max | IsntBounded (Digit+Offset≥2 b d o d+o≥2) = next-number-is-greater-Digit+Offset≥2 xs ¬max d+o≥2
--
-- gap : ∀ {b d o}
--     → (xs : Num b d o)
--     → ¬ (Maximum xs)
--     → ℕ
-- gap {b} xs ¬max = (toℕ (next-number xs ¬max) ∸ toℕ xs) * b
--
-- gap>0 : ∀ {b d o}
--     → (xs : Num (suc b) d o)
--     → (¬max : ¬ (Maximum xs))
--     → gap xs ¬max > 0
-- gap>0 {b} {d} {o} xs ¬max = (start
--         1
--     ≤⟨ s≤s (reflexive (sym (n∸n≡0 (toℕ xs)))) ⟩
--         suc (toℕ xs ∸ toℕ xs)
--     ≤⟨ reflexive (sym (+-∸-assoc 1 {toℕ xs} ≤-refl)) ⟩
--         suc (toℕ xs) ∸ toℕ xs
--     ≤⟨ ∸-mono {suc (toℕ xs)} {toℕ (next-number xs ¬max)} {toℕ xs} (next-number-is-greater xs ¬max) ≤-refl ⟩
--         toℕ (next-number xs ¬max) ∸ toℕ xs
--     □) *-mono (s≤s z≤n)
--
-- next-number-is-LUB-Base≡0 : ∀ {d o}
--     → (xs : Num 0 (suc d) o)
--     → (ys : Num 0 (suc d) o)
--     → (¬max : ¬ (Maximum xs))
--     → toℕ ys > toℕ xs
--     → toℕ ys ≥ toℕ (next-number-Base≡0 xs ¬max)
-- next-number-is-LUB-Base≡0 {d} {o} xs ys ¬max prop with Base≡0-view d o
-- next-number-is-LUB-Base≡0 {0} {0} xs ys ¬max prop | HasOnly0 = contradiction (next-number-Base≡0-lemma-1 zero zero xs (s≤s z≤n)) ¬max
-- next-number-is-LUB-Base≡0         ∙  ∙  ¬max ()   | Others bound
-- next-number-is-LUB-Base≡0 {d} {0} ∙ (y ∷ ys) ¬max prop | Others bound =
--     start
--         Digit-toℕ (Digit-fromℕ {d} 1 0 bound) 0 + 0
--     ≤⟨ +n-mono 0 (reflexive (Digit-toℕ-fromℕ {d} {0} (suc zero) bound z≤n)) ⟩
--         1
--     ≤⟨ prop ⟩
--         Fin.toℕ y + 0 + toℕ ys * 0
--     □
-- next-number-is-LUB-Base≡0 {d} {suc o} ∙ (y ∷ ys) ¬max prop | Others bound =
--     start
--         Digit-toℕ (Digit-fromℕ (suc o) (suc o) bound) (suc o) + 0
--     ≤⟨ +n-mono 0 (reflexive (Digit-toℕ-fromℕ {d} (suc o) bound ≤-refl)) ⟩
--         suc o + 0
--     ≤⟨ +n-mono 0 (m≤n+m (suc o) (Fin.toℕ y)) ⟩
--         Digit-toℕ y (suc o) + zero
--     ≤⟨ reflexive (cong (λ w → Digit-toℕ y (suc o) + w) (sym (*-right-zero (toℕ ys)))) ⟩
--         Digit-toℕ y (suc o) + toℕ ys * zero
--     □
-- next-number-is-LUB-Base≡0 (x ∷ xs) ∙        ¬max ()   | Others bound
-- next-number-is-LUB-Base≡0 {d} {o} (x ∷ xs) (y ∷ ys) ¬max prop | Others bound with Greatest? x
-- next-number-is-LUB-Base≡0 {d} {o} (x ∷ xs) (y ∷ ys) ¬max prop | Others bound | yes greatest = contradiction (Base≡0-lemma x xs greatest) ¬max
-- next-number-is-LUB-Base≡0 {d} {o} (x ∷ xs) (y ∷ ys) ¬max prop | Others bound | no ¬greatest =
--     start
--         Digit-toℕ (digit+1 x ¬greatest) o + toℕ xs * 0
--     ≤⟨ +n-mono (toℕ xs * 0) (reflexive (Digit-toℕ-digit+1 x ¬greatest)) ⟩
--         suc (toℕ (x ∷ xs))
--     ≤⟨ prop ⟩
--         toℕ (y ∷ ys)
--     □
--
--
--
--
-- next-number-is-LUB-HasNoDigit : ∀ {b o}
--     → (xs : Num b 0 o)
--     → (ys : Num b 0 o)
--     → (¬max : ¬ (Maximum xs))
--     → toℕ ys ≥ toℕ (next-number-HasNoDigit xs ¬max)
-- next-number-is-LUB-HasNoDigit {b} {o} ∙         ys ¬max = contradiction (HasNoDigit-lemma b o) ¬max
-- next-number-is-LUB-HasNoDigit         (() ∷ xs) ys ¬max
--
-- next-number-is-LUB-Digit+Offset≥2 : ∀ {b d o}
--     → (xs : Num (suc b) (suc d) o)
--     → (ys : Num (suc b) (suc d) o)
--     → (¬max : ¬ (Maximum xs))
--     → (d+o≥2 : 2 ≤ suc (d + o))
--     → toℕ ys > toℕ xs
--     → toℕ ys ≥ toℕ (next-number-Digit+Offset≥2 xs ¬max d+o≥2)
-- next-number-is-LUB-Digit+Offset≥2 ∙ ∙ ¬max d+o≥2 ()
-- next-number-is-LUB-Digit+Offset≥2 {b} {d} {zero} ∙ (y ∷ ys) ¬max d+o≥2 prop =
--     start
--         Digit-toℕ (Digit-fromℕ {d} (suc zero) zero (≤-pred d+o≥2)) 0 + 0
--     ≤⟨ +n-mono 0 (reflexive (Digit-toℕ-fromℕ {d} 1 (≤-pred d+o≥2) z≤n)) ⟩
--         suc zero
--     ≤⟨ prop ⟩
--         toℕ (y ∷ ys)
--     □
-- next-number-is-LUB-Digit+Offset≥2 {b} {d} {suc o} ∙ (y ∷ ys) ¬max d+o≥2 prop =
--     start
--         Digit-toℕ (Digit-fromℕ {d} (suc o) (suc o) (next-number-Digit+Offset≥2-lemma-1 d (suc o) d+o≥2)) (suc o) + zero
--     ≤⟨ +n-mono 0 (reflexive (Digit-toℕ-fromℕ {d} {suc o} (suc o) (m≤n+m (suc o) d) ≤-refl)) ⟩
--         suc o + 0
--     ≤⟨ (m≤n+m (suc o) (Fin.toℕ y)) +-mono z≤n ⟩
--         Digit-toℕ y (suc o) + toℕ ys * suc b
--     ≤⟨ ≤-refl ⟩
--         toℕ (y ∷ ys)
--     □
-- next-number-is-LUB-Digit+Offset≥2 {b} {d} {o} (x ∷ xs) ∙ ¬max d+o≥2 ()
-- next-number-is-LUB-Digit+Offset≥2 {b} {d} {o} (x ∷ xs) (y ∷ ys) ¬max d+o≥2 prop with Greatest? x
-- next-number-is-LUB-Digit+Offset≥2 {b} {d} {o} (x ∷ xs) (y ∷ ys) ¬max d+o≥2 prop | yes greatest
--     with suc d ≤? (toℕ (next-number-Digit+Offset≥2 xs (next-number-Digit+Offset≥2-lemma-2 x xs ¬max greatest d+o≥2) d+o≥2) ∸ toℕ xs) * suc b
-- next-number-is-LUB-Digit+Offset≥2 {b} {d} {o} (x ∷ xs) (y ∷ ys) ¬max d+o≥2 prop | yes greatest | yes gapped =
--     let
--         ¬max-xs : ¬ (Maximum xs)
--         ¬max-xs = next-number-Digit+Offset≥2-lemma-2 x xs ¬max greatest d+o≥2
--
--         next-xs : Num (suc b) (suc d) o
--         next-xs = next-number-Digit+Offset≥2 xs ¬max-xs d+o≥2
--
--         ⟦ys⟧>⟦xs⟧ : toℕ ys > toℕ xs
--         ⟦ys⟧>⟦xs⟧ = tail-mono-strict x y xs ys greatest prop
--
--         ⟦ys⟧≥⟦next-xs⟧ : toℕ ys ≥ toℕ next-xs
--         ⟦ys⟧≥⟦next-xs⟧ = next-number-is-LUB-Digit+Offset≥2 xs ys ¬max-xs d+o≥2 ⟦ys⟧>⟦xs⟧
--     in
--     start
--         toℕ (z ∷ next-xs)
--     ≤⟨ ≤-refl ⟩
--         o + toℕ next-xs * suc b
--     ≤⟨ m≤n+m o (Fin.toℕ y) +-mono (*n-mono (suc b) ⟦ys⟧≥⟦next-xs⟧) ⟩
--         Digit-toℕ y o + toℕ ys * suc b
--     ≤⟨ ≤-refl ⟩
--         toℕ (y ∷ ys)
--     □
--
-- next-number-is-LUB-Digit+Offset≥2 {b} {d} {o} (x ∷ xs) (y ∷ ys) ¬max d+o≥2 prop | yes greatest | no ¬gapped =
--     let
--
--         ¬max-xs : ¬ (Maximum xs)
--         ¬max-xs = next-number-Digit+Offset≥2-lemma-2 x xs ¬max greatest d+o≥2
--
--         next-xs : Num (suc b) (suc d) o
--         next-xs = next-number-Digit+Offset≥2 xs ¬max-xs d+o≥2
--
--         gap : ℕ
--         gap = (toℕ next-xs ∸ toℕ xs) * suc b
--
--         gap>0 : gap > 0
--         gap>0 = (start
--                 1
--             ≤⟨ s≤s (reflexive (sym (n∸n≡0 (toℕ xs)))) ⟩
--                 suc (toℕ xs ∸ toℕ xs)
--             ≤⟨ reflexive (sym (+-∸-assoc 1 {toℕ xs} ≤-refl)) ⟩
--                 suc (toℕ xs) ∸ toℕ xs
--             ≤⟨ ∸-mono {suc (toℕ xs)} {toℕ next-xs} {toℕ xs} (next-number-is-greater-Digit+Offset≥2 xs ¬max-xs d+o≥2) ≤-refl ⟩
--                 toℕ next-xs ∸ toℕ xs
--             □) *-mono (s≤s z≤n)
--
--         next-xs>xs : toℕ next-xs > toℕ xs
--         next-xs>xs = next-number-is-greater-Digit+Offset≥2 xs ¬max-xs d+o≥2
--
--         next-xs-upper-bound : toℕ next-xs * suc b ∸ toℕ xs * suc b ≤ suc (Digit-toℕ x o)
--         next-xs-upper-bound =
--             start
--                 toℕ next-xs * suc b ∸ toℕ xs * suc b
--             ≤⟨ reflexive (sym (*-distrib-∸ʳ (suc b) (toℕ next-xs) (toℕ xs))) ⟩
--                 (toℕ next-xs ∸ toℕ xs) * suc b
--             ≤⟨ ≤-pred (≰⇒> ¬gapped) ⟩
--                 d
--             ≤⟨ m≤m+n d (suc o) ⟩
--                 d + suc o
--             ≤⟨ reflexive (+-suc d o) ⟩
--                 suc (d + o)
--             ≤⟨ s≤s $ reflexive (sym (toℕ-greatest x greatest)) ⟩
--                 suc (Fin.toℕ x + o)
--             □
--         next-xs-lower-bound : toℕ xs * suc b ≤ toℕ next-xs * suc b
--         next-xs-lower-bound = *n-mono (suc b) (≤-pred (≤-step (next-number-is-greater-Digit+Offset≥2 xs ¬max-xs d+o≥2)))
--
--     in start
--         Digit-toℕ (digit+1-n x greatest gap gap>0 ) o + toℕ next-xs * suc b
--     ≤⟨ +n-mono (toℕ next-xs * suc b) (reflexive (Digit-toℕ-digit+1-n x greatest gap gap>0 (≤-pred $ ≤-step $ ≰⇒> ¬gapped))) ⟩
--         suc (Digit-toℕ x o) ∸ gap + toℕ next-xs * suc b
--     ≤⟨ reflexive (cong (λ w → suc (Digit-toℕ x o) ∸ w + toℕ next-xs * suc b) (*-distrib-∸ʳ (suc b) (toℕ next-xs) (toℕ xs))) ⟩
--         suc (Digit-toℕ x o) ∸ (toℕ next-xs * suc b ∸ toℕ xs * suc b) + toℕ next-xs * suc b
--     ≤⟨ reflexive (m∸[o∸n]+o≡m+n (suc (Digit-toℕ x o)) (toℕ xs * suc b) (toℕ next-xs * suc b) next-xs-lower-bound next-xs-upper-bound) ⟩
--         suc (Digit-toℕ x o) +  toℕ xs * suc b
--     ≤⟨ prop ⟩
--         toℕ (y ∷ ys)
--     □
--
-- next-number-is-LUB-Digit+Offset≥2 {b} {d} {o} (x ∷ xs) (y ∷ ys) ¬max d+o≥2 prop | no ¬greatest =
--     start
--         toℕ (digit+1 x ¬greatest ∷ xs)
--     ≤⟨ ≤-refl ⟩
--         Digit-toℕ (digit+1 x ¬greatest) o + toℕ xs * suc b
--     ≤⟨ +n-mono (toℕ xs * suc b) (reflexive (Digit-toℕ-digit+1 x ¬greatest)) ⟩
--         suc (Fin.toℕ x + o + toℕ xs * suc b)
--     ≤⟨ prop ⟩
--         Fin.toℕ y + o + toℕ ys * suc b
--     ≤⟨ ≤-refl ⟩
--         toℕ (y ∷ ys)
--     □
--
-- next-number-is-LUB : ∀ {b d o}
--     → (xs : Num b d o)
--     → (ys : Num b d o)
--     → (¬max : ¬ (Maximum xs))
--     → toℕ ys > toℕ xs
--     → toℕ ys ≥ toℕ (next-number xs ¬max)
-- next-number-is-LUB {b} {d} {o} xs ys ¬max prop with boundedView b d o
-- next-number-is-LUB xs ys ¬max prop | IsBounded (Base≡0 d o) = next-number-is-LUB-Base≡0 xs ys ¬max prop
-- next-number-is-LUB xs ys ¬max prop | IsBounded (HasNoDigit b o) = next-number-is-LUB-HasNoDigit xs ys ¬max
-- next-number-is-LUB xs ys ¬max prop | IsBounded (HasOnly0 b) = contradiction (HasOnly0-Maximum (suc b) xs) ¬max
-- next-number-is-LUB xs ys ¬max prop | IsntBounded (Digit+Offset≥2 b d o d+o≥2) = next-number-is-LUB-Digit+Offset≥2 xs ys ¬max d+o≥2 prop

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

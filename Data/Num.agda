module Data.Num where

open import Data.Num.Core renaming
    (   carry to carry'
    ;   carry-lower-bound to carry-lower-bound'
    ;   carry-upper-bound to carry-upper-bound'
    )
open import Data.Num.Maximum
open import Data.Num.Bounded
open import Data.Num.Next
open import Data.Num.Increment
open import Data.Num.Continuous

open import Data.Nat
open import Data.Nat.Properties
open import Data.Nat.Properties.Simple
open import Data.Nat.Properties.Extra
open import Data.Nat.DM

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

1+ : ∀ {b d o}
    → {cont : True (Continuous? b d o)}
    → (xs : Num b d o)
    → Num b d o
1+ {cont = cont} xs = proj₁ (toWitness cont xs)

1+-toℕ : ∀ {b d o}
    → {cont : True (Continuous? b d o)}
    → (xs : Num b d o)
    → ⟦ 1+ {cont = cont} xs ⟧ ≡ suc ⟦ xs ⟧
1+-toℕ {cont = cont} xs = proj₂ (toWitness cont xs)

sum : ∀ {d}
    → (o : ℕ)
    → (x y : Digit (suc d))
    → ℕ
sum o x y = Digit-toℕ x o + Digit-toℕ y o

sum≥o : ∀ {d} o
    → (x y : Digit (suc d))
    → sum o x y ≥ o
sum≥o o x y = start
        o
    ≤⟨ m≤n+m o (Fin.toℕ x) ⟩
        Digit-toℕ x o
    ≤⟨ m≤m+n (Digit-toℕ x o) (Digit-toℕ y o) ⟩
        sum o x y
    □

sum-upper-bound : ∀ {d} o
    → (x y : Digit (suc d))
    → sum o x y ≤ (d + o) + (d + o)
sum-upper-bound {d} o x y =
    start
        Digit-toℕ x o + Digit-toℕ y o
    ≤⟨ ≤-pred (Digit-upper-bound o x) +-mono ≤-pred (Digit-upper-bound o y) ⟩
        d + o + (d + o)
    □

--  0   o                d+o          d+o+(1⊔o)×b
----|---|-----------------|----------------|
--    o          d              (1⊔o)×b
--                        [----------------] "buffer capacity"


data Sum : (b d o : ℕ) (x y : Digit (suc d)) → Set where
    Below : ∀ {b d o x y}
        → (leftover : Digit (suc d))
        → (property : Digit-toℕ leftover o ≡ sum o x y)
        → Sum b d o x y
    Within : ∀ {b d o x y}
        → (leftover carry : Digit (suc d))
        → (property : Digit-toℕ leftover o + (Digit-toℕ carry o) * suc b ≡ sum o x y)
        → Sum b d o x y
    Above : ∀ {b d o x y}
        → (leftover carry : Digit (suc d))
        → (property : Digit-toℕ leftover o + (Digit-toℕ carry o) * suc b ≡ sum o x y)
        → Sum b d o x y



sumView : ∀ b d o
    → (¬gapped : (1 ⊔ o) * suc b ≤ suc d)
    → (proper : 2 ≤ suc d + o)
    → (x y : Digit (suc d))
    → Sum b d o x y
sumView b d o ¬gapped proper x y with (sum o x y) ≤? d + o
sumView b d o ¬gapped proper x y | yes below
    = Below
        (Digit-fromℕ leftover o leftover-upper-bound)
        property
    where
        leftover : ℕ
        leftover = sum o x y

        leftover-upper-bound : leftover ≤ d + o
        leftover-upper-bound = below

        property :
              Digit-toℕ (Digit-fromℕ leftover o leftover-upper-bound) o
            ≡ sum o x y
        property =
            begin
                Digit-toℕ (Digit-fromℕ (sum o x y) o below) o
            ≡⟨ Digit-fromℕ-toℕ (sum o x y) (sum≥o o x y) below ⟩
                sum o x y
            ∎
sumView b d o ¬gapped proper x y | no ¬below with (sum o x y) ≤? d + o + (1 ⊔ o) * (suc b)
sumView b d o ¬gapped proper x y | no ¬below | yes within
    = Within
        (Digit-fromℕ leftover o leftover-upper-bound)
        (Digit-fromℕ carry    o carry-upper-bound)
        property

    where
        base : ℕ
        base = suc b

        carry : ℕ
        carry = carry' o

        sum≥carry*base : sum o x y ≥ carry * base
        sum≥carry*base =
            start
                carry * base
            ≤⟨ m≤m+n (carry * base) o ⟩
                carry * base + o
            ≤⟨ +n-mono o ¬gapped ⟩
                suc (d + o)
            ≤⟨ ≰⇒> ¬below ⟩
                sum o x y
            □


        leftover : ℕ
        leftover = sum o x y ∸ carry * base

        leftover-lower-bound : leftover ≥ o
        leftover-lower-bound =
            start
                o
            ≈⟨ sym (m+n∸n≡m o (carry * base)) ⟩
                o + carry * base ∸ carry * base
            ≈⟨ cong (λ w → w ∸ carry * base) (+-comm o (carry * base)) ⟩
                carry * base + o ∸ carry * base
            ≤⟨ ∸n-mono (carry * base) (+n-mono o ¬gapped) ⟩
                suc d + o ∸ carry * base
            ≤⟨ ∸n-mono (carry * base) (≰⇒> ¬below) ⟩
                leftover
            □


        leftover-upper-bound : leftover ≤ d + o
        leftover-upper-bound = +n-mono-inverse (carry * base) $
            start
                leftover + carry * base
            ≈⟨ refl ⟩
                sum o x y ∸ carry * base + carry * base
            ≈⟨ m∸n+n≡m sum≥carry*base ⟩
                sum o x y
            ≤⟨ within ⟩
                d + o + carry * base
            □

        carry-lower-bound : carry ≥ o
        carry-lower-bound = carry-lower-bound'

        carry-upper-bound : carry ≤ d + o
        carry-upper-bound = carry-upper-bound' {d} {o} proper

        property :
              Digit-toℕ (Digit-fromℕ leftover o leftover-upper-bound) o
            + Digit-toℕ (Digit-fromℕ    carry o    carry-upper-bound) o * base
            ≡ sum o x y
        property =
            begin
                Digit-toℕ (Digit-fromℕ leftover o leftover-upper-bound) o
              + Digit-toℕ (Digit-fromℕ    carry o    carry-upper-bound) o * base
            ≡⟨ cong₂
                (λ l c → l + c * base)
                (Digit-fromℕ-toℕ leftover leftover-lower-bound leftover-upper-bound)
                (Digit-fromℕ-toℕ    carry    carry-lower-bound    carry-upper-bound)
            ⟩
                leftover + carry * base
            ≡⟨ refl ⟩
                sum o x y ∸ carry * base + carry * base
            ≡⟨ m∸n+n≡m sum≥carry*base ⟩
                sum o x y
            ∎

sumView b d o ¬gapped proper x y | no ¬below | no ¬within with (sum o x y ∸ ((d + o) + (1 ⊔ o) * (suc b))) divMod (suc b)
sumView b d o ¬gapped proper x y | no ¬below | no ¬within | result quotient remainder divModProp _ _
    = Above
        (Digit-fromℕ leftover o leftover-upper-bound)
        (Digit-fromℕ carry    o carry-upper-bound)
        property
    where

        base : ℕ
        base = suc b

        carry : ℕ
        carry = (1 ⊓ Fin.toℕ remainder) + quotient + (1 ⊔ o)

        divModProp' : sum o x y ≡ Fin.toℕ remainder + quotient * base + (d + o + (1 ⊔ o) * base)
        divModProp' =
            begin
                sum o x y
            ≡⟨ sym (m∸n+n≡m (<⇒≤ (≰⇒> ¬within))) ⟩
                sum o x y ∸ (d + o + (1 ⊔ o) * base) + (d + o + (1 ⊔ o) * base)
            ≡⟨ cong (λ w → w + ((d + o) + (1 ⊔ o) * base)) divModProp ⟩
                Fin.toℕ remainder + quotient * base + ((d + o) + (1 ⊔ o) * base)
            ∎

        leftover : ℕ
        leftover = sum o x y ∸ carry * base

        leftover-lower-bound-lemma :
              (remainder : Fin base)
            → (prop : sum o x y ∸ (d + o + (1 ⊔ o) * base) ≡ Fin.toℕ remainder + quotient * base)
            → sum o x y ≥ o + ((1 ⊓ Fin.toℕ remainder) + quotient + (1 ⊔ o)) * base
        leftover-lower-bound-lemma z prop =
            start
                o + (quotient + (1 ⊔ o)) * base
            ≤⟨ +n-mono ((quotient + (1 ⊔ o)) * base) (m≤n+m o d) ⟩
                d + o + (quotient + (1 ⊔ o)) * base
            ≈⟨ cong (λ w → d + o + w) (distribʳ-*-+ base quotient (1 ⊔ o)) ⟩
                d + o + (quotient * base + (1 ⊔ o) * base)
            ≈⟨ a+[b+c]≡b+[a+c] (d + o) (quotient * base) ((1 ⊔ o) * base) ⟩
                quotient * base + ((d + o) + (1 ⊔ o) * base)
            ≈⟨ cong (λ w → w + ((d + o) + (1 ⊔ o) * base)) (sym prop) ⟩
                (sum o x y ∸ ((d + o) + (1 ⊔ o) * base)) + ((d + o) + (1 ⊔ o) * base)
            ≈⟨ m∸n+n≡m (<⇒≤ (≰⇒> ¬within)) ⟩
                sum o x y
            □
        leftover-lower-bound-lemma (s r) prop =
            start
                o + ((1 ⊓ (Fin.toℕ (s r))) + quotient + (1 ⊔ o)) * base
            ≈⟨ refl ⟩
                o + (1 + (quotient + (1 ⊔ o))) * base
            ≈⟨ cong (λ w → o + w) (distribʳ-*-+ base 1 (quotient + (1 ⊔ o))) ⟩
                o + (1 * base + (quotient + (1 ⊔ o)) * base)
            ≈⟨ cong (λ w → o + (1 * base + w)) (distribʳ-*-+ base quotient (1 ⊔ o)) ⟩
                o + (1 * base + (quotient * base + (1 ⊔ o) * base))
            ≤⟨ n+-mono o
                (n+-mono (1 * base)
                    (+n-mono ((1 ⊔ o) * base)
                        (m≤n+m (quotient * base) (Fin.toℕ r)))) ⟩
                o + (1 * base + (Fin.toℕ r + quotient * base + (1 ⊔ o) * base))
            ≈⟨ a+[b+c]≡b+[a+c] o (1 * base) (Fin.toℕ r + quotient * base + (1 ⊔ o) * base) ⟩
                1 * base + (o + (Fin.toℕ r + quotient * base + (1 ⊔ o) * base))
            ≤⟨ +n-mono (o + (Fin.toℕ r + quotient * base + (1 ⊔ o) * base)) (*n-mono base (m≤m⊔n 1 o)) ⟩
                (1 ⊔ o) * base + (o + (Fin.toℕ r + quotient * base + (1 ⊔ o) * base))
            ≤⟨ +n-mono (o + ((Fin.toℕ r) + quotient * base + (1 ⊔ o) * base)) ¬gapped ⟩
                suc d + (o + ((Fin.toℕ r) + quotient * base + (1 ⊔ o) * base))
            ≈⟨ cong suc (sym (+-assoc d o ((Fin.toℕ r) + quotient * base + (1 ⊔ o) * base))) ⟩
                suc (d + o + ((Fin.toℕ r) + quotient * base + (1 ⊔ o) * base))
            ≈⟨ sym (+-suc (d + o) ((Fin.toℕ r) + quotient * base + (1 ⊔ o) * base)) ⟩
                d + o + suc ((Fin.toℕ r) + quotient * base + (1 ⊔ o) * base)
            ≈⟨ a+[b+c]≡b+[a+c] (d + o) (suc (Fin.toℕ r) + quotient * base) ((1 ⊔ o) * base) ⟩
                suc (Fin.toℕ r) + quotient * base + ((d + o) + (1 ⊔ o) * base)
            ≈⟨ cong (λ w → w + ((d + o) + (1 ⊔ o) * base)) (sym prop) ⟩
                (sum o x y ∸ ((d + o) + (1 ⊔ o) * base)) + ((d + o) + (1 ⊔ o) * base)
            ≈⟨ m∸n+n≡m (<⇒≤ (≰⇒> ¬within)) ⟩
                sum o x y
            □

        leftover-lower-bound : leftover ≥ o
        leftover-lower-bound =
            start
                o
            ≈⟨ sym (m+n∸n≡m o (carry * base)) ⟩
                o + carry * base ∸ carry * base
            ≤⟨ ∸n-mono (carry * base) (leftover-lower-bound-lemma remainder divModProp) ⟩
                sum o x y ∸ carry * base
            ≈⟨ refl ⟩
                leftover
            □

        leftover-upper-bound-lemma :
              (remainder : Fin base)
            → (prop : sum o x y ∸ (d + o + (1 ⊔ o) * base) ≡ Fin.toℕ remainder + quotient * base)
            → sum o x y ≤ d + o + ((1 ⊓ Fin.toℕ remainder) + quotient + (1 ⊔ o)) * base
        leftover-upper-bound-lemma z prop =
            start
                sum o x y
            ≈⟨ sym (m∸n+n≡m (<⇒≤ (≰⇒> ¬within))) ⟩
                (sum o x y ∸ ((d + o) + (1 ⊔ o) * base)) + ((d + o) + (1 ⊔ o) * base)
            ≈⟨ cong (λ w → w + ((d + o) + (1 ⊔ o) * base)) prop ⟩
                quotient * base + ((d + o) + (1 ⊔ o) * base)
            ≈⟨ a+[b+c]≡b+[a+c] (quotient * base) (d + o) ((1 ⊔ o) * base) ⟩
                d + o + (quotient * base + (1 ⊔ o) * base)
            ≈⟨ cong (λ w → d + o + w) (sym (distribʳ-*-+ base quotient (1 ⊔ o))) ⟩
                d + o + (quotient + (1 ⊔ o)) * base
            □
        leftover-upper-bound-lemma (s r) prop =
            start
                sum o x y
            ≈⟨ sym (m∸n+n≡m (<⇒≤ (≰⇒> ¬within))) ⟩
                (sum o x y ∸ ((d + o) + (1 ⊔ o) * base)) + ((d + o) + (1 ⊔ o) * base)
            ≈⟨ cong (λ w → w + ((d + o) + (1 ⊔ o) * base)) prop ⟩
                suc (Fin.toℕ r) + quotient * base + ((d + o) + (1 ⊔ o) * base)
            ≈⟨ a+[b+c]≡b+[a+c] (suc (Fin.toℕ r) + quotient * base) (d + o) ((1 ⊔ o) * base) ⟩
                d + o + (suc (Fin.toℕ r) + quotient * base + (1 ⊔ o) * base)
            ≤⟨ n+-mono (d + o)
                (+n-mono ((1 ⊔ o) * base)
                    (+n-mono (quotient * base)
                        (≤-step (bounded r)))) ⟩
                d + o + (suc quotient * base + (1 ⊔ o) * base)
            ≈⟨ cong (λ w → d + o + w) (sym (distribʳ-*-+ base (suc quotient) (1 ⊔ o))) ⟩
                d + o + (1 + (quotient + (1 ⊔ o))) * base
            ≈⟨ refl ⟩
                d + o + ((1 ⊓ (Fin.toℕ (s r))) + quotient + (1 ⊔ o)) * base
            □

        leftover-upper-bound : leftover ≤ d + o
        leftover-upper-bound =
            start
                leftover
            ≈⟨ refl ⟩
                sum o x y ∸ carry * base
            ≤⟨ ∸n-mono (carry * base) (leftover-upper-bound-lemma remainder divModProp) ⟩
                d + o + carry * base ∸ carry * base
            ≈⟨ m+n∸n≡m (d + o) (carry * base) ⟩
                d + o
            □

        carry-lower-bound : carry ≥ o
        carry-lower-bound =
            start
                o
            ≤⟨ m≤n⊔m o 1 ⟩
                1 ⊔ o
            ≤⟨ m≤n+m (1 ⊔ o) (1 ⊓ Fin.toℕ remainder + quotient) ⟩
                1 ⊓ Fin.toℕ remainder + quotient + (1 ⊔ o)
            □

        carry-upper-bound : carry ≤ d + o
        carry-upper-bound = +n-mono-inverse (d + o) $
            start
                1 ⊓ Fin.toℕ remainder + quotient + (1 ⊔ o) + (d + o)
            ≤⟨ +n-mono (d + o)
                (+n-mono (1 ⊔ o)
                    (+n-mono quotient
                        (m⊓n≤n 1 (Fin.toℕ remainder))))
            ⟩
                Fin.toℕ remainder + quotient + (1 ⊔ o) + (d + o)
            ≈⟨ +-assoc (Fin.toℕ remainder + quotient) (1 ⊔ o) (d + o) ⟩
                Fin.toℕ remainder + quotient + (1 ⊔ o + (d + o))
            ≈⟨ cong (λ w → Fin.toℕ remainder + quotient + w) (+-comm (1 ⊔ o) (d + o)) ⟩
                Fin.toℕ remainder + quotient + (d + o + (1 ⊔ o))
            ≤⟨ +n-mono (d + o + (1 ⊔ o))
                (n+-mono (Fin.toℕ remainder) (m≤m*1+n quotient b))
            ⟩
                Fin.toℕ remainder + quotient * base + (d + o + (1 ⊔ o))
            ≤⟨ n+-mono (Fin.toℕ remainder + quotient * base)
                (n+-mono (d + o)
                    (m≤m*1+n (1 ⊔ o) b))
            ⟩
                Fin.toℕ remainder + quotient * base + (d + o + (1 ⊔ o) * base)
            ≈⟨ cong (λ w → w + (d + o + (1 ⊔ o) * base)) (sym divModProp) ⟩
                sum o x y ∸ (d + o + (1 ⊔ o) * base) + (d + o + (1 ⊔ o) * base)
            ≈⟨ m∸n+n≡m (<⇒≤ (≰⇒> ¬within)) ⟩
                sum o x y
            ≤⟨ sum-upper-bound o x y ⟩
                d + o + (d + o)
            □

        property :
              Digit-toℕ (Digit-fromℕ leftover o leftover-upper-bound) o
            + Digit-toℕ (Digit-fromℕ    carry o    carry-upper-bound) o * base
            ≡ sum o x y
        property =
            begin
                Digit-toℕ (Digit-fromℕ leftover o leftover-upper-bound) o
              + Digit-toℕ (Digit-fromℕ    carry o    carry-upper-bound) o * base
            ≡⟨ cong₂
                (λ l c → l + c * base)
                (Digit-fromℕ-toℕ leftover leftover-lower-bound leftover-upper-bound)
                (Digit-fromℕ-toℕ    carry    carry-lower-bound    carry-upper-bound)
            ⟩
                leftover + carry * base
            ≡⟨ refl ⟩
                sum o x y ∸ carry * base + carry * base
            ≡⟨ m∸n+n≡m $
                start
                    carry * base
                ≤⟨ m≤n+m (carry * base) o ⟩
                    o + carry * base
                ≤⟨ leftover-lower-bound-lemma remainder divModProp ⟩
                    sum o x y
                □
            ⟩
                sum o x y
            ∎

n+-Proper : ∀ {b d o}
    → (¬gapped : (1 ⊔ o) * suc b ≤ suc d)
    → (proper : suc d + o ≥ 2)
    → (x : Digit (suc d))
    → (xs : Num (suc b) (suc d) o)
    → Num (suc b) (suc d) o
n+-Proper {b} {d} {o} ¬gapped proper x xs with sumView b d o ¬gapped proper x (lsd xs)
n+-Proper ¬gapped proper x (_ ∙)    | Below leftover property = leftover ∙
n+-Proper ¬gapped proper x (_ ∷ xs) | Below leftover property = leftover ∷ xs
n+-Proper ¬gapped proper x (_ ∙)    | Within leftover carry property = leftover ∷ carry ∙
n+-Proper ¬gapped proper x (_ ∷ xs) | Within leftover carry property = leftover ∷ n+-Proper ¬gapped proper carry xs
n+-Proper ¬gapped proper x (_ ∙)    | Above leftover carry property = leftover ∷ carry ∙
n+-Proper ¬gapped proper x (_ ∷ xs) | Above leftover carry property = leftover ∷ n+-Proper ¬gapped proper carry xs

n+-Proper-toℕ : ∀ {b d o}
    → (¬gapped : (1 ⊔ o) * suc b ≤ suc d)
    → (proper : suc d + o ≥ 2)
    → (x : Digit (suc d))
    → (xs : Num (suc b) (suc d) o)
    → ⟦ n+-Proper ¬gapped proper x xs ⟧ ≡ Digit-toℕ x o + ⟦ xs ⟧
n+-Proper-toℕ {b} {d} {o} ¬gapped proper x xs with sumView b d o ¬gapped proper x (lsd xs)
n+-Proper-toℕ {b} {d} {o} ¬gapped proper x (_ ∙)    | Below leftover property = property
n+-Proper-toℕ {b} {d} {o} ¬gapped proper x (x' ∷ xs) | Below leftover property =
    begin
        ⟦ leftover ∷ xs ⟧
    ≡⟨ refl ⟩
        Digit-toℕ leftover o + ⟦ xs ⟧ * suc b
    ≡⟨ cong (λ w → w + ⟦ xs ⟧ * suc b) property ⟩
        Digit-toℕ x o + Digit-toℕ x' o + ⟦ xs ⟧ * suc b
    ≡⟨ +-assoc (Digit-toℕ x o) (Digit-toℕ x' o) (⟦ xs ⟧ * suc b) ⟩
        Digit-toℕ x o + ⟦ x' ∷ xs ⟧
    ∎
n+-Proper-toℕ {b} {d} {o} ¬gapped proper x (_ ∙)    | Within leftover carry property = property
n+-Proper-toℕ {b} {d} {o} ¬gapped proper x (x' ∷ xs) | Within leftover carry property =
    begin
        ⟦ leftover ∷ n+-Proper ¬gapped proper carry xs ⟧
    ≡⟨ refl ⟩
        Digit-toℕ leftover o + ⟦ n+-Proper ¬gapped proper carry xs ⟧ * suc b
    ≡⟨ cong (λ w → Digit-toℕ leftover o + w * suc b) (n+-Proper-toℕ ¬gapped proper carry xs) ⟩
        Digit-toℕ leftover o + (Digit-toℕ carry o + ⟦ xs ⟧) * suc b
    ≡⟨ cong (λ w → Digit-toℕ leftover o + w) (distribʳ-*-+ (suc b) (Digit-toℕ carry o) ⟦ xs ⟧) ⟩
        Digit-toℕ leftover o + ((Digit-toℕ carry o) * suc b + ⟦ xs ⟧ * suc b)
    ≡⟨ sym (+-assoc (Digit-toℕ leftover o) ((Digit-toℕ carry o) * suc b) (⟦ xs ⟧ * suc b)) ⟩
        Digit-toℕ leftover o + (Digit-toℕ carry o) * suc b + ⟦ xs ⟧ * suc b
    ≡⟨ cong (λ w → w + ⟦ xs ⟧ * suc b) property ⟩
        Digit-toℕ x o + Digit-toℕ x' o + ⟦ xs ⟧ * suc b
    ≡⟨ +-assoc (Digit-toℕ x o) (Digit-toℕ x' o) (⟦ xs ⟧ * suc b) ⟩
        Digit-toℕ x o + (Digit-toℕ x' o + ⟦ xs ⟧ * suc b)
    ∎
n+-Proper-toℕ {b} {d} {o} ¬gapped proper x (_ ∙)    | Above leftover carry property = property
n+-Proper-toℕ {b} {d} {o} ¬gapped proper x (x' ∷ xs) | Above leftover carry property =
    begin
        ⟦ leftover ∷ n+-Proper ¬gapped proper carry xs ⟧
    ≡⟨ refl ⟩
        Digit-toℕ leftover o + ⟦ n+-Proper ¬gapped proper carry xs ⟧ * suc b
    ≡⟨ cong (λ w → Digit-toℕ leftover o + w * suc b) (n+-Proper-toℕ ¬gapped proper carry xs) ⟩
        Digit-toℕ leftover o + (Digit-toℕ carry o + ⟦ xs ⟧) * suc b
    ≡⟨ cong (λ w → Digit-toℕ leftover o + w) (distribʳ-*-+ (suc b) (Digit-toℕ carry o) ⟦ xs ⟧) ⟩
        Digit-toℕ leftover o + ((Digit-toℕ carry o) * suc b + ⟦ xs ⟧ * suc b)
    ≡⟨ sym (+-assoc (Digit-toℕ leftover o) ((Digit-toℕ carry o) * suc b) (⟦ xs ⟧ * suc b)) ⟩
        Digit-toℕ leftover o + (Digit-toℕ carry o) * suc b + ⟦ xs ⟧ * suc b
    ≡⟨ cong (λ w → w + ⟦ xs ⟧ * suc b) property ⟩
        Digit-toℕ x o + Digit-toℕ x' o + ⟦ xs ⟧ * suc b
    ≡⟨ +-assoc (Digit-toℕ x o) (Digit-toℕ x' o) (⟦ xs ⟧ * suc b) ⟩
        Digit-toℕ x o + (Digit-toℕ x' o + ⟦ xs ⟧ * suc b)
    ∎

data N+Closed : (b d o : ℕ) → Set where
    IsContinuous : ∀ {b d o} → (cont : True (Continuous? b d o)) → N+Closed b d o
    ℤₙ : ∀ {o} → N+Closed 1 1 o

n+-ℤₙ : ∀ {o}
    → (n : Digit 1)
    → (xs : Num 1 1 (o))
    → Num 1 1 o
n+-ℤₙ n xs = n ∷ xs

n+-ℤₙ-toℕ : ∀ {o}
    → (n : Digit 1)
    → (xs : Num 1 1 o)
    → ⟦ n+-ℤₙ n xs ⟧ ≡ Digit-toℕ n o + ⟦ xs ⟧
n+-ℤₙ-toℕ {o} n xs =
    begin
        Fin.toℕ n + o + ⟦ xs ⟧ * suc zero
    ≡⟨ cong (λ w → Fin.toℕ n + o + w) (*-right-identity ⟦ xs ⟧) ⟩
        Fin.toℕ n + o + ⟦ xs ⟧
    ∎

n+ : ∀ {b d o}
    → {cond : N+Closed b d o}
    → (n : Digit d)
    → (xs : Num b d o)
    → Num b d o
n+ {b} {d} {o} {IsContinuous cont} n xs with numView b d o
n+ {_} {_} {_} {IsContinuous ()}   n xs | NullBase d o
n+ {_} {_} {_} {IsContinuous cont} n xs | NoDigits b o = NoDigits-explode xs
n+ {_} {_} {_} {IsContinuous ()}   n xs | AllZeros b
n+ {_} {_} {_} {IsContinuous cont} n xs | Proper b d o proper with Gapped#0? b d o
n+ {_} {_} {_} {IsContinuous ()}   n xs | Proper b d o proper | yes gapped#0
n+ {_} {_} {_} {IsContinuous cont} n xs | Proper b d o proper | no ¬gapped#0 = n+-Proper (≤-pred (≰⇒> ¬gapped#0)) proper n xs
n+ {_} {_} {_} {ℤₙ}                n xs = n+-ℤₙ n xs

n+-toℕ : ∀ {b d o}
    → {cond : N+Closed b d o}
    → (n : Digit d)
    → (xs : Num b d o)
    → ⟦ n+ {cond = cond} n xs ⟧ ≡ Digit-toℕ n o + ⟦ xs ⟧
n+-toℕ {b} {d} {o} {IsContinuous cont} n xs with numView b d o
n+-toℕ {_} {_} {_} {IsContinuous ()}   n xs | NullBase d o
n+-toℕ {_} {_} {_} {IsContinuous cont} n xs | NoDigits b o = NoDigits-explode xs
n+-toℕ {_} {_} {_} {IsContinuous ()}   n xs | AllZeros b
n+-toℕ {_} {_} {_} {IsContinuous cont} n xs | Proper b d o proper with Gapped#0? b d o
n+-toℕ {_} {_} {_} {IsContinuous ()}   n xs | Proper b d o proper | yes gapped#0
n+-toℕ {_} {_} {_} {IsContinuous cont} n xs | Proper b d o proper | no ¬gapped#0 = n+-Proper-toℕ (≤-pred (≰⇒> ¬gapped#0)) proper n xs
n+-toℕ {_} {_} {_} {ℤₙ}                n xs = n+-ℤₙ-toℕ n xs


-- left-bounded infinite interval of natural number
data Nat : ℕ → Set where
    from : ∀ offset   → Nat offset
    suc  : ∀ {offset} → Nat offset → Nat offset

Nat-toℕ : ∀ {offset} → Nat offset → ℕ
Nat-toℕ (from offset) = offset
Nat-toℕ (suc n)       = suc (Nat-toℕ n)

Nat-fromℕ : ∀ offset
    → (n : ℕ)
    → .(offset ≤ n)
    → Nat offset
Nat-fromℕ offset n       p with offset ≟ n
Nat-fromℕ offset n       p | yes eq = from offset
Nat-fromℕ offset zero    p | no ¬eq = from offset
Nat-fromℕ offset (suc n) p | no ¬eq = suc (Nat-fromℕ offset n (≤-pred (≤∧≢⇒< p ¬eq)))


Nat-fromℕ-toℕ : ∀ offset
    → (n : ℕ)
    → (p : offset ≤ n)
    → Nat-toℕ (Nat-fromℕ offset n p) ≡ n
Nat-fromℕ-toℕ offset n       p with offset ≟ n
Nat-fromℕ-toℕ offset n       p | yes eq = eq
Nat-fromℕ-toℕ .0      zero z≤n | no ¬eq = refl
Nat-fromℕ-toℕ offset (suc n) p | no ¬eq =
    begin
        suc (Nat-toℕ (Nat-fromℕ offset n (≤-pred (≤∧≢⇒< p ¬eq))))
    ≡⟨ cong suc (Nat-fromℕ-toℕ offset n (≤-pred (≤∧≢⇒< p ¬eq))) ⟩
        suc n
    ∎

fromNat : ∀ {b d o}
    → {cont : True (Continuous? b (suc d) o)}
    → Nat o
    → Num b (suc d) o
fromNat               (from offset) = z ∙
fromNat {cont = cont} (suc nat)     = 1+ {cont = cont} (fromNat {cont = cont} nat)

toℕ-fromNat : ∀ b d o
    → (cont : True (Continuous? b (suc d) o))
    → (n : ℕ)
    → (p : o ≤ n)
    → ⟦ fromNat {b} {d} {o} {cont = cont} (Nat-fromℕ o n p) ⟧ ≡ n
toℕ-fromNat b d o cont n       p with o ≟ n
toℕ-fromNat b d o cont n       p | yes eq = cong (_+_ zero) eq
toℕ-fromNat b d .0 cont zero z≤n | no ¬eq = refl
toℕ-fromNat b d o cont (suc n) p | no ¬eq =
    begin
        ⟦ 1+ {b} {cont = cont} (fromNat (Nat-fromℕ o n (≤-pred (≤∧≢⇒< p ¬eq)))) ⟧
    ≡⟨ 1+-toℕ {b} (fromNat {cont = cont} (Nat-fromℕ o n (≤-pred (≤∧≢⇒< p ¬eq)))) ⟩
        suc ⟦ fromNat {cont = cont} (Nat-fromℕ o n (≤-pred (≤∧≢⇒< p ¬eq))) ⟧
    -- mysterious agda bug, this refl must stay here
    ≡⟨ refl ⟩
        suc ⟦ fromNat {cont = cont} (Nat-fromℕ o n (≤-pred (≤∧≢⇒< p ¬eq))) ⟧
    ≡⟨ cong suc (toℕ-fromNat b d o cont n (≤-pred (≤∧≢⇒< p ¬eq))) ⟩
        suc n
    ∎
-- -- a partial function that only maps ℕ to Continuous Nums
-- fromℕ : ∀ {b d o}
--     → {cond : N+Closed b d o}
--     → ℕ
--     → Num b (suc d) o
-- fromℕ {cond = cond} zero = z ∙
-- fromℕ {cond = cond} (suc n) = {!   !}

-- fromℕ {cont = cont} zero = z ∙
-- fromℕ {cont = cont} (suc n) = 1+ {cont = cont} (fromℕ {cont = cont} n)

-- toℕ-fromℕ : ∀ {b d o}
--     → {cont : True (Continuous? b (suc d) o)}
--     → (n : ℕ)
--     → ⟦ fromℕ {cont = cont} n ⟧ ≡ n + o
-- toℕ-fromℕ {_} {_} {_} {cont} zero = refl
-- toℕ-fromℕ {b} {d} {o} {cont} (suc n) =
--     begin
--         ⟦ 1+ {cont = cont} (fromℕ {cont = cont} n) ⟧
--     ≡⟨ 1+-toℕ {cont = cont} (fromℕ {cont = cont} n) ⟩
--         suc ⟦ fromℕ {cont = cont} n ⟧
--     ≡⟨ cong suc (toℕ-fromℕ {cont = cont} n) ⟩
--         suc (n + o)
--     ∎

⊹-Proper : ∀ {b d o}
    → (¬gapped : (1 ⊔ o) * suc b ≤ suc d)
    → (proper : suc d + o ≥ 2)
    → (xs ys : Num (suc b) (suc d) o)
    → Num (suc b) (suc d) o
⊹-Proper ¬gapped proper (x ∙)    ys       = n+-Proper ¬gapped proper x ys
⊹-Proper ¬gapped proper (x ∷ xs) (y ∙)    = n+-Proper ¬gapped proper y (x ∷ xs)
⊹-Proper {b} {d} {o} ¬gapped proper (x ∷ xs) (y ∷ ys) with sumView b d o ¬gapped proper x y
⊹-Proper ¬gapped proper (x ∷ xs) (y ∷ ys) | Below leftover property = leftover ∷ ⊹-Proper ¬gapped proper xs ys
⊹-Proper ¬gapped proper (x ∷ xs) (y ∷ ys) | Within leftover carry property = leftover ∷ n+-Proper ¬gapped proper carry (⊹-Proper ¬gapped proper xs ys)
⊹-Proper ¬gapped proper (x ∷ xs) (y ∷ ys) | Above leftover carry property = leftover ∷ n+-Proper ¬gapped proper carry (⊹-Proper ¬gapped proper xs ys)

⊹-ℤₙ : ∀ {o}
    → (xs ys : Num 1 1 o)
    → Num 1 1 o
⊹-ℤₙ (x ∙) ys = x ∷ ys
⊹-ℤₙ (x ∷ xs) ys = x ∷ ⊹-ℤₙ xs ys

_⊹_ : ∀ {b d o}
    → {cond : N+Closed b d o}
    → (xs ys : Num b d o)
    → Num b d o
_⊹_ {b} {d} {o} {IsContinuous cont} xs ys with numView b d o
_⊹_ {cond = IsContinuous ()} xs ys | NullBase d o
_⊹_ {cond = IsContinuous cont} xs ys | NoDigits b o = NoDigits-explode xs
_⊹_ {cond = IsContinuous ()} xs ys | AllZeros b
_⊹_ {cond = IsContinuous cont} xs ys | Proper b d o proper with Gapped#0? b d o
_⊹_ {cond = IsContinuous ()} xs ys | Proper b d o proper | yes ¬gapped#0
_⊹_ {cond = IsContinuous cont} xs ys | Proper b d o proper | no ¬gapped#0 = ⊹-Proper (≤-pred (≰⇒> ¬gapped#0)) proper xs ys
_⊹_ {cond = ℤₙ} xs ys = ⊹-ℤₙ xs ys

infix 4 _≋_

_≋_ : ∀ {b d o}
    → (xs ys : Num b d o)
    → Set
xs ≋ ys = ⟦ xs ⟧ ≡ ⟦ ys ⟧

module RandomAccessList where

open import BuildingBlock

open import Data.Unit using (⊤; tt)
open import Data.Empty using (⊥)
open import Data.Nat
open import Data.Product

open import Relation.Nullary using (Dec; yes; no)
open import Relation.Nullary.Negation using (¬?)
open import Relation.Nullary.Decidable -- using (map′; False; True; ⌊_⌋)

open import Relation.Binary.PropositionalEquality as PropEq
    using (_≡_; _≢_; refl; cong; trans; sym)


-- parameterized by the level of the least significant digit
data RandomAccessList (A : Set) : ℕ → Set where
    []   : ∀ {n} → RandomAccessList A n
    0∷_  : ∀ {n} → RandomAccessList A (suc n) → RandomAccessList A n
    _1∷_ : ∀ {n} → BinaryLeafTree A n → RandomAccessList A (suc n) → RandomAccessList A n

--------------------------------------------------------------------------------
-- to ℕ

⟦_⟧ : ∀ {A n} → RandomAccessList A n → ℕ
⟦   []    ⟧ = zero
⟦   0∷ xs ⟧ = 2 * ⟦ xs ⟧
⟦ _ 1∷ xs ⟧ = 1 + 2 * ⟦ xs ⟧

n*a≡0⇒a≡0 : (a n : ℕ) → 0 < n → n * a ≡ 0 → a ≡ 0
n*a≡0⇒a≡0 a       zero    ()        n*a≡0
n*a≡0⇒a≡0 zero    (suc n) (s≤s z≤n) a+n*a≡0 = refl
n*a≡0⇒a≡0 (suc a) (suc n) (s≤s z≤n) ()


--------------------------------------------------------------------------------
-- predicates

Null? : ∀ {A n} → (xs : RandomAccessList A n) → Dec (⟦ xs ⟧ ≡ 0)
Null?    []     = yes refl
Null? (  0∷ xs) = map′ (cong (λ w → 2 * w)) (n*a≡0⇒a≡0 ⟦ xs ⟧ 2 (s≤s z≤n)) (Null? xs)
Null? (x 1∷ xs) = no (λ ())

--------------------------------------------------------------------------------
-- operations

incr : ∀ {A n} → BinaryLeafTree A n → RandomAccessList A n → RandomAccessList A n
incr a    []     = a 1∷ []
incr a (  0∷ xs) = a 1∷ xs
incr a (x 1∷ xs) = 0∷ (incr (Node a x) xs)

-- borrow from the first non-zero digit, and splits it like so (1:xs)
borrow : ∀ {A n} → (xs : RandomAccessList A n) → False (Null? xs) → RandomAccessList A n × RandomAccessList A n
borrow [] ()
borrow (0∷ xs) q with Null? xs
borrow (0∷ xs) () | yes p
borrow (0∷ xs) tt | no ¬p = borrow {!   !} {!   !}
borrow (x 1∷ xs) q = x 1∷ [] , (0∷ xs)

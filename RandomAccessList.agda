module RandomAccessList where

open import BuildingBlock

open import Data.Unit using (tt)
open import Data.Nat
open import Data.Nat.Properties.Simple
open import Data.Product as Prod
open import Data.Product hiding (map)
open import Function
open import Relation.Nullary using (Dec; yes; no; ¬_)
open import Relation.Nullary.Decidable using (False; fromWitnessFalse)
open import Relation.Binary.PropositionalEquality as PropEq
    using (_≡_; _≢_; refl; cong; trans; sym; inspect)
open PropEq.≡-Reasoning

--------------------------------------------------------------------------------
--  data type

--  parameterized by the level of the least significant digit
data RandomAccessList (A : Set) : ℕ → Set where
    []   : ∀ {n} → RandomAccessList A n
    0∷_  : ∀ {n} → RandomAccessList A (suc n) → RandomAccessList A n
    _1∷_ : ∀ {n} → BinaryLeafTree A n → RandomAccessList A (suc n) → RandomAccessList A n

--------------------------------------------------------------------------------
-- examples

private
    a : RandomAccessList ℕ 0
    a = Leaf zero 1∷ []
    b : RandomAccessList ℕ 1
    b = (Node (Leaf zero) (Leaf zero)) 1∷ []
    c : RandomAccessList ℕ 1
    c = 0∷ ((Node (Node (Leaf zero) (Leaf zero)) (Node (Leaf zero) (Leaf zero))) 1∷ [])
    d : RandomAccessList ℕ 1
    d = []
    d' : RandomAccessList ℕ 0
    d' = 0∷ d
    e : RandomAccessList ℕ 0
    e = []
--------------------------------------------------------------------------------
-- to ℕ

⟦_⟧ₙ : ∀ {A n} → RandomAccessList A n → ℕ
⟦      [] ⟧ₙ = 0
⟦   0∷ xs ⟧ₙ =     2 * ⟦ xs ⟧ₙ
⟦ x 1∷ xs ⟧ₙ = 1 + 2 * ⟦ xs ⟧ₙ

⟦_⟧ : ∀ {A n} → RandomAccessList A n → ℕ
⟦_⟧ {n = zero } xs = ⟦    xs ⟧ₙ
⟦_⟧ {n = suc n} xs = ⟦_⟧ {n = n} (0∷ xs)

n*a≡0⇒a≡0 : (a n : ℕ) → 0 < n → n * a ≡ 0 → a ≡ 0
n*a≡0⇒a≡0 a       zero    ()        n*a≡0
n*a≡0⇒a≡0 zero    (suc n) (s≤s z≤n) a+n*a≡0 = refl
n*a≡0⇒a≡0 (suc a) (suc n) (s≤s z≤n) ()

⟦xs⟧ₙ≡0⇒⟦xs⟧≡0 : ∀ {A n}
            → (xs : RandomAccessList A n)
            → ⟦ xs ⟧ₙ ≡ 0
            → ⟦ xs ⟧ ≡ 0
⟦xs⟧ₙ≡0⇒⟦xs⟧≡0 {n = zero } xs p = p
⟦xs⟧ₙ≡0⇒⟦xs⟧≡0 {n = suc n} xs p = ⟦xs⟧ₙ≡0⇒⟦xs⟧≡0 (0∷ xs) (cong (_*_ 2) p)

⟦xs⟧≡0⇒⟦xs⟧ₙ≡0 : ∀ {A n}
            → (xs : RandomAccessList A n)
            → ⟦ xs ⟧ ≡ 0
            → ⟦ xs ⟧ₙ ≡ 0
⟦xs⟧≡0⇒⟦xs⟧ₙ≡0 {n = zero } xs p = p
⟦xs⟧≡0⇒⟦xs⟧ₙ≡0 {n = suc n} xs p = n*a≡0⇒a≡0 ⟦ xs ⟧ₙ 2 (s≤s z≤n) (⟦xs⟧≡0⇒⟦xs⟧ₙ≡0 (0∷ xs) p)


--------------------------------------------------------------------------------
-- predicates


Null? : ∀ {A n} → (xs : RandomAccessList A n) → Dec (⟦ xs ⟧ ≡ 0)
Null? {n = zero } (     []) = yes refl
Null? {n = zero } (  0∷ xs) with ⟦ xs ⟧
Null? {n = zero } (0∷ xs) | zero = yes refl
Null? {n = zero } (0∷ xs) | suc a = no (λ ())
Null? {n = zero } (x 1∷ xs) = no (λ ())
Null? {n = suc n} (     xs) = Null? {n = n} (0∷ xs)

--------------------------------------------------------------------------------
-- operations

-- numerical: +1
-- container: insertion
incr : ∀ {A n} → BinaryLeafTree A n → RandomAccessList A n → RandomAccessList A n
incr a    []     = a 1∷ []
incr a (  0∷ xs) = a 1∷ xs
incr a (x 1∷ xs) = 0∷ (incr (Node a x) xs)

-- not needed for the moment
-- numerical: carry
carry : ∀ {A n} → BinaryLeafTree A n → BinaryLeafTree A n → BinaryLeafTree A (suc n)
carry x y = Node x y

-- numerical: +
-- container: merge
_++_ : ∀ {A n} → RandomAccessList A n → RandomAccessList A n → RandomAccessList A n
[]        ++ ys        = ys
(  0∷ xs) ++ []        =   0∷ xs
(  0∷ xs) ++ (  0∷ ys) =   0∷ (xs ++ ys)
(  0∷ xs) ++ (x 1∷ ys) = x 1∷ (xs ++ ys)
(x 1∷ xs) ++ []        = x 1∷ xs
(x 1∷ xs) ++ (  0∷ ys) = x 1∷ (xs ++ ys)
(x 1∷ xs) ++ (y 1∷ ys) =   0∷ (incr (Node x y) (xs ++ ys))

shift : ∀ {A n} → RandomAccessList A n → RandomAccessList A (suc n)
shift [] = []
shift (0∷ xs) = xs
shift (x 1∷ xs) = xs

-- borrow from the first non-zero digit, and splits it like so (1:xs)
-- numerical: borrow
borrow : ∀ {A n} → (xs : RandomAccessList A n) → False (Null? xs) → RandomAccessList A n × RandomAccessList A n
borrow {n = zero } (     []) ()
borrow {n = zero } (  0∷ xs) q with Null? xs
borrow {n = zero } (  0∷ xs) () | yes p
borrow {n = zero } (  0∷ xs) q  | no ¬p = Prod.map 0∷_ 0∷_ (borrow xs (fromWitnessFalse ¬p))
borrow {n = zero } (x 1∷ xs) q = x 1∷ [] , 0∷ xs
borrow {n = suc n} (     xs) q with Null? xs
borrow {n = suc n} (     xs) () | yes p
borrow {n = suc n} (     xs) q | no ¬p = Prod.map shift shift (borrow (0∷ xs) (fromWitnessFalse ¬p))

-- numerical: -1
-- container: deletion
decr : ∀ {A n} → (xs : RandomAccessList A n) → False (Null? xs) → RandomAccessList A n
decr {n = zero } (     []) ()
decr {n = zero } (  0∷ xs) q with Null? xs
decr {n = zero } (  0∷ xs) () | yes p
decr {n = zero } (  0∷ xs) q  | no ¬p = 0∷_ (proj₂ (borrow xs (fromWitnessFalse ¬p)))
decr {n = zero } (x 1∷ xs) q = 0∷ xs
decr {n = suc n} (     xs) q with Null? xs
decr {n = suc n} (     xs) () | yes p
decr {n = suc n} (     xs) q | no ¬p = shift (decr (0∷ xs) (fromWitnessFalse ¬p))

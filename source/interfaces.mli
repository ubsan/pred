(**
  the [Interfaces] module is for interfaces that a type may fulfill,
  as well as miscellaneous utilities.

  Each interface is layed out as follows:
    - [Implementation] is the module type that an implementer must fulfill.
    - [Interface] is the module type that a functor which parametrizes over
      the interface should take.
    - [Make] is the functor that transforms [Implementation] into [Interface].

*)

(**
  useful for having types that are parametrized in reality,
  but not in the interface.

  one might implement {!Result_monad} with a functor over the error type,
  for example - this is done in {!Result.Monad}.
*)
module type Type = sig
  (** the type that should be passed to the interface *)
  type t
end

(**
  the infamous burrito of functional programming lore.

  an implementation must give two functions:
    - [wrap], which takes a value and wraps it
    - [>>=], prounounced bind, which calls a function on the wrapped value

  for more information, see
  {{: https://wiki.haskell.org/Monad} the Haskell wiki};
  note that Haskell uses the term [return],
  where [Pred] uses [wrap].

  any implementation of [Monad] should follow these laws:
    - [(wrap a >>= k) = (k a)]
    - [(m >>= wrap) = m]
    - [(m >>= (fun x -> k x >>= h)) = ((m >>= k) >>= h)]

  in words:
    - wrap and then bind should be equivalent to doing nothing
    - bind and then wrap should be equivalent to doing nothing
    - it should not matter whether bind is associated left, or right

  The monad in this module also allows for associated comonadic data.
  For example, a compiler might have a [span] type,
  which should go along with each item.
  If a type's monad does not have comonadic data,
  then [type 'a comonad = 'a] suffices.
*)
module Monad : sig
  module type Implementation = sig
    type 'a t

    type 'a comonad

    val ( >>= ) : 'a t -> ('a comonad -> 'b t) -> 'b t

    val wrap : 'a -> 'a t
  end

  module type Interface = sig
    type 'a t

    type 'a comonad

    val ( >>= ) : 'a t -> ('a comonad -> 'b t) -> 'b t

    val wrap : 'a -> 'a t

    module Let_syntax : sig
      val bind : 'a t -> f:('a comonad -> 'b t) -> 'b t

      val map : 'a t -> f:('a comonad -> 'b) -> 'b t

      val both : 'a t -> 'b t -> ('a comonad * 'b comonad) t
    end
  end

  module Make (M : Implementation) :
    Interface with type 'a t = 'a M.t and type 'a comonad = 'a M.comonad
end

(**
  [Result_monad] is an extension to regular {!Monad},
  with support for an error type.
  
  It should be implemented by any [result]-like types,
  instead of the regular {!Monad},
  because it gives access to [wrap_err].
*)
module Result_monad : sig
  module type Implementation = sig
    type error

    include Monad.Implementation

    val wrap_err : error -> 'a t
  end

  module type Interface = sig
    type error

    include Monad.Interface

    val wrap_err : error -> 'a t
  end

  module Make (M : Implementation) :
    Interface
    with type error = M.error
     and type 'a t = 'a M.t
     and type 'a comonad = 'a M.comonad
end

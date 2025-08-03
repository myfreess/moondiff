///|
trait Elab {
  elab(Self, LineWidths) -> Syntax
}

///|
impl Elab for @syntax.Impl with elab(impl_, line_widths) {
  match impl_ {
    TopView(
      quantifiers~,
      source_ty~,
      view_type_name~,
      view_type_loc~,
      view_constrs~,
      view_func_name~,
      parameters~,
      params_loc~,
      body~,
      vis~,
      loc~,
      attrs~
    ) => ...
    TopImpl(
      self_ty~,
      trait_~,
      method_name~,
      has_error~,
      quantifiers~,
      params~,
      ret_ty~,
      err_ty~,
      body~,
      vis~,
      loc~,
      attrs~,
      doc~
    ) => ...
    TopBatchTraitAlias(pkg~, targets~, vis~, loc~, attrs~, is_list~, doc~) =>
      ...
    TopBatchTypeAlias(pkg~, targets~, vis~, loc~, attrs~, is_list~, doc~) => ...
    TopTrait(_) => ...
    TopLetDef(_) => ...
    TopFuncAlias(_) => ...
    TopFuncDef(fun_decl~, decl_body~, loc~) => ...
    TopTypeDef(_) => ...
    TopTest(_) => ...
    TopExpr(_) => ...
    TopImplRelation(_) => ...
  }
}

///|
impl Elab for @syntax.FunDecl with elab(fundecl, line_widths) {
  let vis = Elab::elab(fundecl.vis, line_widths)
  let name = Elab::elab(fundecl.name, line_widths)
  let typename = if fundecl.type_name is Some(type_name) {
    Elab::elab(type_name, line_widths)
  } else {
    Syntax::default()
  }
  let quantifiers = fundecl.quantifiers
    .map(Elab::elab(_, line_widths))
    .to_array()
  ...
}

///|
impl Elab for @syntax.Parameter with elab(parameter, line_widths) {
  match parameter {
    DiscardPositional(loc~, ty=None) =>
      Syntax::atom(
        content="_",
        position=line_widths.loc_to_spans(loc),
        kind=Normal,
      )
    DiscardPositional(loc~, ty=Some(ty)) => {
      // TODO: calculate the underscore position
      let underscore_loc = loc.sub(1)
      let underscore = Syntax::atom(
        content="_",
        position=line_widths.loc_to_spans(underscore_loc),
        kind=Normal,
      )
      let ty = Elab::elab(ty, line_widths)
      Syntax::simple_list(
        open_position=loc.start_to_spans(),
        children=[underscore, ty],
        close_position=loc.end_to_spans(),
      )
    }
    Positional(binder~, ty=Some(ty))
    | QuestionOptional(binder~, ty=Some(ty))
    | Labelled(binder~, ty=Some(ty))
    | Optional(binder~, ty=Some(ty), ..) => ...
    Positional(binder~, ty=None)
    | QuestionOptional(binder~, ty=None)
    | Labelled(binder~, ty=None)
    | Optional(binder~, ty=None, ..) => Elab::elab(binder, line_widths)
  }
}

///|
impl Elab for @syntax.Type with elab(ty, line_widths) {
  match ty {
    Option(question_loc~, ty~, loc~) => {
      let question = Syntax::atom(
        content="?",
        position=line_widths.loc_to_spans(question_loc),
        kind=Normal,
      )
      let inner_type = Elab::elab(ty, line_widths)
      Syntax::simple_list(
        open_position=loc.start_to_spans(),
        children=[inner_type, question],
        close_position=loc.end_to_spans(),
      )
    }
    Name(constr_id~, tys~, loc~) => {
      let constr_str = constr_id.id.to_str()
      let constr_id = Syntax::atom(
        content=constr_str,
        position=line_widths.loc_to_spans(constr_id.loc),
        kind=Normal,
      )
      if tys.is_empty() {
        constr_id
      } else {
        // TODO: get real open/close position
        // [A, B, C] -> startpos = pos of '[', endpos = pos of ']'
        let (tys_open_pos, tys_close_pos) = if tys is More(ty, tail=Empty) {
          (loc_of_type(ty).start_to_spans(), loc_of_type(ty).end_to_spans())
        } else {
          (
            loc_of_type(tys.head().unwrap()).start_to_spans(),
            loc_of_type(tys.last().unwrap()).end_to_spans(),
          )
        }
        let tys = tys.map(Elab::elab(_, line_widths)).to_array()
        Syntax::simple_list(
          open_position=loc.start_to_spans(),
          children=[
            constr_id,
            Syntax::simple_list(
              open_position=tys_open_pos,
              children=tys,
              close_position=tys_close_pos,
            ),
          ],
          close_position=loc.end_to_spans(),
        )
      }
    }
    Tuple(loc~, tys~) => {
      let children = tys.map(Elab::elab(_, line_widths)).to_array()
      Syntax::simple_list(
        open_position=loc.start_to_spans(),
        children~,
        close_position=loc.end_to_spans(),
      )
    }
    Arrow(loc~, args~, res~, err~, is_async~) => {
      let args = args.map(Elab::elab(_, line_widths)).to_array()
      let res = Elab::elab(res, line_widths)
      let err = if err is NoErrorType {
        Syntax::default()
      } else {
        Elab::elab(err, line_widths)
      }
      let is_async = if is_async { Syntax::atom(content="async", position=loc.sub(5).start_to_spans(), kind=Normal) } else { Syntax::default() }
      let args = panic()
      Syntax::simple_list(
        open_position=loc.start_to_spans(),
        children=[is_async, args, res, err],
        close_position=loc.end_to_spans(),
      )
    }
    Any(_) => ...
    Object(_) => ...
  }
}

impl Elab for @syntax.ErrorType with elab(err_ty, line_widths) {
  match err_ty {
    Noraise(loc~) => {
      Syntax::atom(
        content="noraise",
        position=line_widths.loc_to_spans(loc),
        kind=Normal,
      )
    }
    NoErrorType => Syntax::default()
    DefaultErrorType(loc~) => {
      Syntax::atom(
        content="raise",
        position=line_widths.loc_to_spans(loc),
        kind=Normal,
      )
    }
    ErrorType(ty~) => {
      Elab::elab(ty, line_widths)
    }
    MaybeError(ty~) => {
      let loc = loc_of_type(ty)
      Syntax::atom(
        content="raise?",
        position=line_widths.loc_to_spans(loc),
        kind=Normal,
      )
    }
  }
}

///|
impl Elab for @syntax.TypeVarBinder with elab(type_var_binder, line_widths) {
  if type_var_binder.constraints.is_empty() {
    Syntax::atom(
      content=type_var_binder.name,
      position=line_widths.loc_to_spans(type_var_binder.loc),
      kind=Normal,
    )
  } else {
    let tvar_name = Syntax::atom(
      content=type_var_binder.name,
      position=line_widths.loc_to_spans(type_var_binder.loc),
      kind=Normal,
    )
    // TODO: separate tvar_name and constraints
    let children = type_var_binder.constraints
      .map(Elab::elab(_, line_widths))
      .add(tvar_name)
      .to_array()
    Syntax::simple_list(
      open_position=type_var_binder.loc.start_to_spans(),
      children~,
      close_position=type_var_binder.loc.end_to_spans(),
    )
  }
}

///|
impl Elab for @syntax.TypeVarConstraint with elab(
  type_var_constraint,
  line_widths,
) {
  let content = type_var_constraint.trait_.to_str()
  Syntax::atom(
    content~,
    position=line_widths.loc_to_spans(type_var_constraint.loc),
    kind=Normal,
  )
}

///|
impl Elab for @syntax.TypeName with elab(type_name, line_widths) {
  let content = type_name.name.to_str()
  Syntax::atom(
    content~,
    position=line_widths.loc_to_spans(type_name.loc),
    kind=Normal,
  )
}

///|
impl Elab for @syntax.Binder with elab(binder, line_widths) {
  Syntax::atom(
    content=binder.name,
    position=line_widths.loc_to_spans(binder.loc),
    kind=Normal,
  )
}

///|
impl Elab for @syntax.Visibility with elab(vis, line_widths) {
  match vis {
    Default => Syntax::default()
    Pub(loc~, attr~) => {
      let content = if attr is Some(attr) { "pub(\{attr})" } else { "pub" }
      Syntax::atom(
        content~,
        position=line_widths.loc_to_spans(loc),
        kind=Normal,
      )
    }
    Priv(loc~) => {
      let content = "priv"
      Syntax::atom(
        content~,
        position=line_widths.loc_to_spans(loc),
        kind=Normal,
      )
    }
  }
}

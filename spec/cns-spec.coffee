fs = require 'fs'
path = require 'path'

describe "Cream & Sugar grammar", ->
  grammar = null

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage("language-cns")

    runs ->
      grammar = atom.grammars.grammarForScopeName("source.cns")

  it "parses the grammar", ->
    expect(grammar).toBeTruthy()
    expect(grammar.scopeName).toBe "source.cns"

  it "tokenizes regexp", ->
    {tokens} = grammar.tokenizeLine("/^#\/?/")

    expect(tokens[0]).toEqual value: "/^#\/?/", scopes: ["source.cns", "string.regexp.cns"]


  it "tokenizes comments", ->
    {tokens} = grammar.tokenizeLine("# I am a comment")

    expect(tokens[0]).toEqual value: "#", scopes: ["source.cns", "comment.line.number-sign.cns", "punctuation.definition.comment.cns"]
    expect(tokens[1]).toEqual value: " I am a comment", scopes: ["source.cns", "comment.line.number-sign.cns"]

    {tokens} = grammar.tokenizeLine("\#{Comment}")

    expect(tokens[0]).toEqual value: "#", scopes: ["source.cns", "comment.line.number-sign.cns", "punctuation.definition.comment.cns"]
    expect(tokens[1]).toEqual value: "{Comment}", scopes: ["source.cns", "comment.line.number-sign.cns"]

  it "tokenizes this as a special variable", ->
    {tokens} = grammar.tokenizeLine("this")

    expect(tokens[0]).toEqual value: "this", scopes: ["source.cns", "variable.language.this.cns"]

  it "tokenizes variable assignments", ->
    {tokens} = grammar.tokenizeLine("something = b")
    expect(tokens[0]).toEqual value: "something", scopes: ["source.cns", "variable.assignment.cns"]
    expect(tokens[2]).toEqual value: "=", scopes: ["source.cns", "keyword.operator.cns"]
    expect(tokens[3]).toEqual value: " b", scopes: ["source.cns"]

  it "tokenizes operators properly", ->
    operators = ["!", "%", "^", "*", "/", "?", ":", "-", "--", "+", "++", "<", ">", "&", "&&", "..", "...", "|", "||", "new", "delete", "super"]

    for operator in operators
      {tokens} = grammar.tokenizeLine(operator)
      expect(tokens[0]).toEqual value: operator, scopes: ["source.cns", "keyword.operator.cns"]

  it "does not tokenize non-operators as operators", ->
    notOperators = ["(/=", "-->", "=>"]

    for notOperator in notOperators
      {tokens} = grammar.tokenizeLine(notOperator)
      expect(tokens[0]).not.toEqual value: notOperator, scopes: ["source.cns", "keyword.operator.cns"]

  it "tokenizes functions", ->
    {tokens} = grammar.tokenizeLine("foo = fn -> 1")
    expect(tokens[0]).toEqual value: "foo", scopes: ["source.cns", "variable.assignment.cns"]

    {tokens} = grammar.tokenizeLine("foo bar")
    expect(tokens[0]).toEqual value: "foo", scopes: ["source.cns", "entity.name.function.cns"]

    {tokens} = grammar.tokenizeLine("eat food for food in foods")
    expect(tokens[0]).toEqual value: "eat", scopes: ["source.cns", "entity.name.function.cns"]
    expect(tokens[1]).toEqual value: " food ", scopes: ["source.cns"]
    expect(tokens[2]).toEqual value: "for", scopes: ["source.cns", "keyword.control.cns"]
    expect(tokens[3]).toEqual value: " food ", scopes: ["source.cns"]
    expect(tokens[4]).toEqual value: "in", scopes: ["source.cns", "keyword.control.cns"]
    expect(tokens[5]).toEqual value: " foods", scopes: ["source.cns"]

    {tokens} = grammar.tokenizeLine("foo @bar")
    expect(tokens[0]).toEqual value: "foo", scopes: ["source.cns", "entity.name.function.cns"]
    expect(tokens[2]).toEqual value: "@bar", scopes: ["source.cns", "variable.other.readwrite.instance.cns"]

    {tokens} = grammar.tokenizeLine("foo baz, @bar")
    expect(tokens[0]).toEqual value: "foo", scopes: ["source.cns", "entity.name.function.cns"]
    expect(tokens[1]).toEqual value: " baz", scopes: ["source.cns"]
    expect(tokens[2]).toEqual value: ",", scopes: ["source.cns", "meta.delimiter.object.comma.cns"]
    expect(tokens[4]).toEqual value: "@bar", scopes: ["source.cns", "variable.other.readwrite.instance.cns"]

  it "does not tokenize booleans as functions", ->
    {tokens} = grammar.tokenizeLine("false true")
    expect(tokens[0]).toEqual value: "false", scopes: ["source.cns", "constant.language.boolean.false.cns"]
    expect(tokens[2]).toEqual value: "true", scopes: ["source.cns", "constant.language.boolean.true.cns"]

    {tokens} = grammar.tokenizeLine("true if false")
    expect(tokens[0]).toEqual value: "true", scopes: ["source.cns", "constant.language.boolean.true.cns"]
    expect(tokens[2]).toEqual value: "if", scopes: ["source.cns", "keyword.control.cns"]
    expect(tokens[4]).toEqual value: "false", scopes: ["source.cns", "constant.language.boolean.false.cns"]

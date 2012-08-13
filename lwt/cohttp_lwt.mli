(*
 * Copyright (c) 2012 Anil Madhavapeddy <anil@recoil.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 *)

module Request : sig
  type request
  val meth : request -> Code.meth
  val uri : request -> Uri.t
  val version : request -> Code.version
  val path : request -> string
  val header : request -> string -> string list
  val headers : request -> Header.t
  val params_get : request -> Header.t
  val params_post : request -> Header.t
  val param : request -> string -> string list
  val transfer_encoding : request -> string

  val make : ?meth:Code.meth -> ?version:Code.version -> 
    ?encoding:Transfer.encoding -> Header.t -> Uri.t -> request

  val read : Lwt_io.input_channel -> request option Lwt.t
  val read_body : request -> Lwt_io.input_channel -> Transfer.chunk Lwt.t

  val write_header : request -> Lwt_io.output_channel -> unit Lwt.t
  val write_body : string -> request -> Lwt_io.output_channel -> unit Lwt.t
  val write_footer : request -> Lwt_io.output_channel -> unit Lwt.t
  val write : (request -> Lwt_io.output_channel -> unit Lwt.t) -> request -> Lwt_io.output_channel -> unit Lwt.t
end

module Response : sig
  type response
  val version : response -> Code.version
  val status : response -> Code.status_code
  val headers: response -> Header.t

  val make : ?version:Code.version -> ?status:Code.status_code -> 
    ?encoding:Transfer.encoding -> Header.t -> response

  val read : Lwt_io.input_channel -> response option Lwt.t
  val read_body : response -> Lwt_io.input_channel -> Transfer.chunk Lwt.t

  val write_header : response -> Lwt_io.output_channel -> unit Lwt.t
  val write_body : string -> response -> Lwt_io.output_channel -> unit Lwt.t
  val write_footer : response -> Lwt_io.output_channel -> unit Lwt.t
  val write : (response -> Lwt_io.output_channel -> unit Lwt.t) -> 
    response -> Lwt_io.output_channel -> unit Lwt.t
end

module Client : sig
  type response = (Response.response * string Lwt_stream.t) option

  val call : ?headers:Header.t -> ?body:string Lwt_stream.t -> 
    Code.meth -> Uri.t -> response Lwt.t

  val head : ?headers:Header.t -> Uri.t -> response Lwt.t
  val get : ?headers:Header.t -> Uri.t -> response Lwt.t
  val post : ?headers:Header.t -> ?body:string Lwt_stream.t -> Uri.t -> response Lwt.t
  val post_form : ?headers:Header.t -> params:Header.t -> Uri.t -> response Lwt.t
  val put : ?headers:Header.t -> ?body:string Lwt_stream.t -> Uri.t -> response Lwt.t
  val delete : ?headers:Header.t -> Uri.t -> response Lwt.t
end

module Server : sig
  type conn_id
  type response = Response.response * string Lwt_stream.t

  val string_of_conn_id : conn_id -> string

  type config = {
    address : string;
    callback : conn_id -> Request.request -> response Lwt.t;
    conn_closed : conn_id -> unit;
    port : int;
    root_dir : string option;
    timeout : int option;
  }  

  val respond_string :
      ?headers:Header.t ->
      status:Code.status_code ->
      body:string -> unit -> response Lwt.t

  val respond_error : status:Code.status_code -> body:string -> unit -> response Lwt.t

  val main : config -> unit Lwt.t
end

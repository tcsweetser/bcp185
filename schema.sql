--
-- PostgreSQL database dump
--

-- Dumped from database version 15.5 (Debian 15.5-0+deb12u1)
-- Dumped by pg_dump version 15.5 (Debian 15.5-0+deb12u1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: allocated; Type: TABLE; Schema: public; Owner: apnic
--

CREATE TABLE public.allocated (
    rir text,
    economy_iso character varying(2),
    family character varying(4),
    prefix inet,
    size integer,
    allocation_date text,
    allocation_status text
);


ALTER TABLE public.allocated OWNER TO apnic;

--
-- Name: routes; Type: TABLE; Schema: public; Owner: apnic
--

CREATE TABLE public.routes (
    dumptype text,
    exported text,
    protocol character(1),
    nexthop inet,
    asn bigint,
    prefix cidr,
    aspath text,
    origin text
);


ALTER TABLE public.routes OWNER TO apnic;

--
-- Name: allocated_economy_iso_idx; Type: INDEX; Schema: public; Owner: apnic
--

CREATE INDEX allocated_economy_iso_idx ON public.allocated USING btree (economy_iso);


--
-- Name: allocated_prefix_idx; Type: INDEX; Schema: public; Owner: apnic
--

CREATE INDEX allocated_prefix_idx ON public.allocated USING gist (prefix inet_ops);


--
-- Name: allocated_rir_idx; Type: INDEX; Schema: public; Owner: apnic
--

CREATE INDEX allocated_rir_idx ON public.allocated USING btree (rir);


--
-- Name: routes_prefix_idx; Type: INDEX; Schema: public; Owner: apnic
--

CREATE INDEX routes_prefix_idx ON public.routes USING gist (prefix inet_ops);


--
-- PostgreSQL database dump complete
--


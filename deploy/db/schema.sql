--
-- PostgreSQL database dump
--

-- Dumped from database version 12.4
-- Dumped by pg_dump version 13.1 (Ubuntu 13.1-1.pgdg18.04+1)

-- Started on 2021-01-28 11:35:01 CET

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

--
-- TOC entry 11 (class 2615 OID 17616)
-- Name: addons; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA addons;


--
-- TOC entry 10 (class 2615 OID 17489)
-- Name: duo; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA duo;


--
-- TOC entry 9 (class 2615 OID 17485)
-- Name: tmp; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA tmp;


--
-- TOC entry 2 (class 3079 OID 17617)
-- Name: tablefunc; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS tablefunc WITH SCHEMA addons;


--
-- TOC entry 3338 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION tablefunc; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION tablefunc IS 'functions that manipulate whole tables, including crosstab';


--
-- TOC entry 870 (class 1247 OID 18432)
-- Name: fetch_individuals_result_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.fetch_individuals_result_type AS (
	individual_stable_id text,
	dataset_ids text[],
	taxon_id text,
	taxon_id_ontology text,
	taxon_id_ontology_label text,
	sex text,
	sex_ontology text,
	ethnicity text,
	ethnicity_ontology text,
	geographic_origin text,
	geographic_origin_ontology text,
	handovers jsonb,
	pedigrees jsonb,
	diseases jsonb,
	phenotypic_features jsonb,
	ontologies_used jsonb,
	sra_family_id integer,
	race text,
	date_of_birth date,
	weight_kg integer,
	height_cm integer,
	blood_type text,
	medications jsonb,
	procedures jsonb,
	alternative_ids text[],
	alternative_ids_phenopackets text[]
);


--
-- TOC entry 882 (class 1247 OID 18471)
-- Name: fetch_samples_result_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.fetch_samples_result_type AS (
	biosample_stable_id text,
	individual_stable_id text,
	description text,
	biosample_status text,
	biosample_status_ontology text,
	biosample_status_ontology_label text,
	individual_age_at_collection text,
	obtention_procedure text,
	obtention_procedure_ontology text,
	obtention_procedure_ontology_label text,
	tumor_progression text,
	tumor_progression_ontology text,
	tumor_progression_ontology_label text,
	tumor_grade text,
	tumor_grade_ontology text,
	tumor_grade_ontology_label text,
	collection_date date,
	handovers jsonb,
	sample_origins jsonb,
	sample_origins_ontology jsonb,
	ontologies_used jsonb,
	alternative_ids text[],
	study_id text,
	bioproject_id text,
	files jsonb
);


--
-- TOC entry 879 (class 1247 OID 18465)
-- Name: fetch_variants_result_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.fetch_variants_result_type AS (
	variant_id integer,
	assembly_id text,
	chromosome text,
	refseq_id text,
	variant_name text,
	reference text,
	alternate text,
	start integer,
	"end" integer,
	variant_type text,
	aminoacid_changes text[],
	aminoacid_lengths text[],
	codon_changes text[],
	effect_impacts text[],
	exon_ranks text[],
	functional_classes text[],
	gene_codings text[],
	gene_names text[],
	genomic_hgvs_id text[],
	genomic_regions text[],
	genotypes text[],
	molecular_effects text[],
	protein_hgvs_ids text[],
	transcript_biotypes text[],
	transcript_hgvs_ids text[],
	transcript_ids text[],
	genomic_regions_ontology jsonb,
	molecular_effects_ontology jsonb,
	genomic_features_ontology jsonb,
	ontologies_used jsonb,
	dataset_response jsonb
);


--
-- TOC entry 297 (class 1255 OID 18377)
-- Name: add_where_clause_conditions(boolean, text, integer, integer, integer, integer, integer, integer, text, text, text, text, text[], boolean, text, text, integer, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.add_where_clause_conditions(_concat_values boolean, _variant_type text, _start integer, _start_min integer, _start_max integer, _end integer, _end_min integer, _end_max integer, _chromosome text, _reference_bases text, _alternate_bases text, _reference_genome text, _dataset_stable_ids text[], _is_authenticated boolean, _biosample_stable_id text, _individual_stable_id text, _gvariant_id integer, _filters text, OUT _where_clause text) RETURNS text
    LANGUAGE plpgsql
    AS $_$

DECLARE
	_join_variant_table bool;
BEGIN
	_where_clause = '
	WHERE ';
	_join_variant_table = FALSE;
	
	IF _variant_type IS NOT NULL OR _start_min IS NOT NULL OR _end IS NOT NULL 
		OR _reference_bases IS NOT NULL OR _alternate_bases IS NOT NULL
		THEN _join_variant_table = TRUE;
	END IF;

	-- Datasets
	IF NOT _is_authenticated OR _dataset_stable_ids IS NULL OR array_length(_dataset_stable_ids, 1) IS NULL THEN
		-- only query PUBLIC datasets
		_where_clause = _where_clause || '
		dat.access_type=''PUBLIC''';
	END IF;
	
	IF array_length(_dataset_stable_ids, 1) > 0 THEN
		IF NOT _is_authenticated THEN
			_where_clause =  _where_clause || '
			AND';
		END IF;
		_where_clause =  _where_clause || 
			CASE WHEN _concat_values 
			THEN ' dat.stable_id = ANY(' || quote_literal(_dataset_stable_ids)
			ELSE ' dat.stable_id = ANY($7' 
			END
			||')' ;
	END IF;
		
	IF _biosample_stable_id IS NOT NULL THEN
		_where_clause =  _where_clause || '
		AND sam.stable_id=' || CASE WHEN _concat_values 
								THEN quote_literal(_biosample_stable_id)
								ELSE '$13' 
								END;
	END IF;
	
	IF _individual_stable_id IS NOT NULL THEN
		_where_clause =  _where_clause || '
		AND ind.stable_id=' || CASE WHEN _concat_values 
								THEN quote_literal(_individual_stable_id)
								ELSE '$14' 
								END;
	END IF;
	
	IF _gvariant_id IS NOT NULL THEN
		_where_clause =  _where_clause || '
		AND ' || CASE WHEN _concat_values 
								THEN 'var.id=' || _gvariant_id
								ELSE 'var.id=$15' 
								END;
	END IF;
	
	IF _filters IS NOT NULL THEN
		_where_clause = _where_clause || ' 
		AND ' || _filters;
	END IF;

	IF _join_variant_table THEN
	
		IF _variant_type IS NULL AND _alternate_bases IS NULL
		  --THEN RAISE EXCEPTION 'Either _variant_type or _alternate_bases is mandatory';
		  THEN _alternate_bases='*';
		END IF;
		IF _alternate_bases='N' THEN _alternate_bases='*'; END IF; -- Look for any variant	
	
		IF _variant_type IS NOT NULL THEN
			_where_clause = _where_clause || '
			AND var.variant_type=' || CASE WHEN _concat_values 
								THEN quote_literal(_variant_type)
								ELSE '$1' 
								END;
		END IF;

		IF _start_min IS NOT NULL THEN
			_where_clause = _where_clause || '
			AND ' || CASE WHEN _concat_values 
								THEN 'var.start >= ' || _start_min
								ELSE 'var.start >= $9' 
								END || ' 
			AND ' || CASE WHEN _concat_values 
								THEN 'var.start < ' || _start_max
								ELSE 'var.start < $10' 
								END || ' 
			AND ' || CASE WHEN _concat_values 
								THEN 'var.end >= ' || _end_min
								ELSE 'var.end >= $11' 
								END || ' 
			AND ' || CASE WHEN _concat_values 
								THEN 'var.end < ' || _end_max
								ELSE 'var.end < $12' 
								END;
		ELSIF _alternate_bases != '*' OR (_alternate_bases = '*' AND _end IS NULL)
			OR (_alternate_bases IS NULL AND _variant_type IS NOT NULL) THEN
		  	-- Looking for an exact match
			_where_clause = _where_clause || 
				CASE WHEN _concat_values 
				THEN ' AND var.start = ' || _start
				ELSE ' AND var.start = $2' 
				END;
		END IF;

		IF _end IS NOT NULL THEN
			-- Remember that end is exclusive
			IF _alternate_bases = '*' THEN
				-- Looking for any variant within this range
				_where_clause = _where_clause || '
				AND (' || CASE WHEN _concat_values 
								THEN 'var.start >= ' || _start
								ELSE 'var.start >= $2' 
								END || ' 
				AND ' || CASE WHEN _concat_values 
								THEN 'var.start < ' || _end
								ELSE 'var.start < $8' 
								END || ' 
				OR ' || CASE WHEN _concat_values 
								THEN 'var.end >= ' || _start
								ELSE 'var.end >= $2' 
								END || ' 
				AND ' || CASE WHEN _concat_values 
								THEN 'var.end < ' || _end
								ELSE 'var.end < $8' 
								END 
				|| ' )';
			ELSE
				-- Looking for an exact match
				_where_clause = _where_clause || '
				AND ' || CASE WHEN _concat_values 
								THEN 'var.end = ( ' || _end
								ELSE 'var.end = ($8' 
								END 
				|| '-1)';
			END IF;
		END IF;

		-- refseq
		_where_clause = _where_clause || '
		AND var.chromosome= ' || CASE WHEN _concat_values 
								THEN quote_literal(_chromosome)
								ELSE '$3' 
								END;

		-- Reference parameter is not mandatory
		IF _reference_bases IS NOT NULL AND _reference_bases!='N' THEN
			_where_clause=_where_clause || '
			AND var.reference=' || CASE WHEN _concat_values 
								THEN quote_literal(_reference_bases)
								ELSE '$4' 
								END;
		END IF;

		-- Alternate bases
		IF _alternate_bases IS NOT NULL THEN
		  IF _variant_type='INS' THEN
			  _where_clause = _where_clause || '
			  AND var.alternate like var.reference || ' || CASE WHEN _concat_values 
								THEN quote_literal(_alternate_bases)
								ELSE '$5' 
								END || ' || ''%'' ';
			ELSIF _alternate_bases NOT IN ('N','*') THEN
			  _where_clause = _where_clause || '
			  AND var.alternate=' || CASE WHEN _concat_values 
								THEN quote_literal(_alternate_bases)
								ELSE '$5' 
								END;
			END IF;
		END IF;

		-- Convert reference_genome column to lower case
		_where_clause = _where_clause || '
		AND lower(dat.reference_genome)=' || CASE WHEN _concat_values 
								THEN quote_literal(_reference_genome)
								ELSE '$6' 
								END;
	END IF;

	-- #1=_variant_type, #2=_start, #3=_refseq, #4=_reference_bases, #5=_alternate_bases, 
	-- #6=_reference_genome, #7=_dataset_stable_ids, #8=_end, #9=_start_min, #10=_start_max, 
	-- #11=_end_min, #12=_end_max, 
	-- #13=_biosample_stable_id, #14=_individual_stable_id, #15=_gvariant_id
	-- #16=_limit, #17=_offset

END
$_$;


--
-- TOC entry 305 (class 1255 OID 18413)
-- Name: build_crosstab_clause(text, integer, integer, integer, integer, integer, integer, text, text, text, text, text[], boolean, text, text, integer, integer, integer, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.build_crosstab_clause(_variant_type text, _start integer, _start_min integer, _start_max integer, _end integer, _end_min integer, _end_max integer, _refseq text, _reference_bases text, _alternate_bases text, _reference_genome text, _dataset_stable_ids text[], _is_authenticated boolean, _biosample_stable_id text, _individual_stable_id text, _gvariant_id integer, _offset integer, _limit integer, _filters_converted text, _joins_clause text, OUT _crosstab_clause text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
	_where_clause_values_concat text;
BEGIN
	SELECT * INTO _where_clause_values_concat
	FROM public.add_where_clause_conditions(true, _variant_type, _start, _start_min, _start_max, 
											_end, _end_min, _end_max, 
											_refseq, _reference_bases, _alternate_bases, _reference_genome,
											_dataset_stable_ids, _is_authenticated, 
											_biosample_stable_id, _individual_stable_id, _gvariant_id, 
											_filters_converted);
	RAISE NOTICE 'WHERE(2)=%', _where_clause_values_concat;

	_crosstab_clause = '
	LEFT JOIN public.crosstab_variant_annotations_cols(
		$ct$
		SELECT va.variant_id, 
			va.annotation_name, 
			va.annotation_value
		FROM (
			select var.id
			from variant_table var
			' || _joins_clause || _where_clause_values_concat ||
			' ORDER BY var.id
			' || CASE WHEN _limit IS NULL THEN 'LIMIT null' ELSE 'LIMIT ' || _limit END || 
			CASE WHEN _offset IS NULL THEN ' OFFSET null' ELSE ' OFFSET ' || _offset END || '
		)var
		INNER JOIN variant_annotation_table va ON va.variant_id=var.id
		ORDER  BY 1, 2
		$ct$,
		''SELECT DISTINCT annotation_name FROM variant_annotation_table'' -- categories
	)ct ON ct.variant_id=var.id';
	
END
$_$;


--
-- TOC entry 268 (class 1255 OID 16386)
-- Name: count_gvariants(text, integer, integer, integer, integer, integer, integer, character varying, text, text, text, text[], boolean, text, text, integer, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.count_gvariants(_variant_type text, _start integer, _start_min integer, _start_max integer, _end integer, _end_min integer, _end_max integer, _refseq character varying, _reference_bases text, _alternate_bases text, _reference_genome text, _dataset_stable_ids text[], _is_authenticated boolean, _biosample_stable_id text, _individual_stable_id text, _gvariant_id integer, _filters text[]) RETURNS TABLE(_num_total_results bigint)
    LANGUAGE plpgsql
    AS $$

-- PRECONDITIONS:
-- _dataset_stable_ids is optional
-- If _is_authenticated=false or _dataset_stable_ids is empty, only PUBLIC datasets will be queried 
--		(regardless there are registered or controlled in _dataset_stable_ids)
-- If _is_authenticated=true, datasets in _dataset_stable_ids will be queried
-- _offset is the number of rows to be skipped
-- _limit is the number of rows to be returned
-- 	If _limit=null & _offset=null, no pagination is applied
-- Expected combinations:
--		* _reference_genome + _refseq + _alternate_bases + _reference_bases + _start
--		* _reference_genome + _refseq + _alternate_bases + (_reference_bases) + _start + _end
--		* _reference_genome + _refseq + (_variant_type) + _start + _end
--		* _reference_genome + _refseq + (_variant_type) + _start_min + _start_max + _end_min + _end_max

DECLARE
	_query text;
	_where_clause text;
	_filters_converted text;
	_join_individual_table bool;
	_join_sample_table bool;
	_join_pedigree_table bool;
	_join_individual_pedigree_table bool;
	_join_individual_disease_table bool;
	_join_individual_phenotypic_feature_table bool;
BEGIN
	_join_individual_table = FALSE;
	_join_sample_table = FALSE;
	_join_pedigree_table = FALSE;
	_join_individual_pedigree_table = FALSE;
	_join_individual_disease_table = FALSE;
	_join_individual_phenotypic_feature_table = FALSE;

	SELECT * INTO _filters_converted
	FROM public.parse_filters(_filters);

	-- Aliases used in ontology_term_table
	-- 	'ind'
	-- 	'sam'
	-- 	'ind_ped'
	-- 	'ind_dis'
	-- In the future, we may have filters on variant_table
	
	-- Check what other tables should be joined depending on the filters provided
	-- TODO

	SELECT * INTO _where_clause
	FROM public.add_where_clause_conditions(false, _variant_type, _start, _start_min, _start_max, 
											_end, _end_min, _end_max, 
											_refseq, _reference_bases, _alternate_bases, _reference_genome,
											_dataset_stable_ids, _is_authenticated, 
											_biosample_stable_id, _individual_stable_id, _gvariant_id, 
											_filters_converted);
	RAISE NOTICE 'WHERE=%', _where_clause;
	
	IF _where_clause LIKE '%ind.%' 
		OR _where_clause LIKE '%ped.%'
		OR _where_clause LIKE '%ind_ped.%' 
		OR _where_clause LIKE '%ind_dis.%' 
		OR _where_clause LIKE '%ind_phf.%' 
	THEN 
		_join_sample_table=TRUE;
		_join_individual_table=TRUE; 
	END IF;
	IF _where_clause LIKE '%sam.%' THEN _join_sample_table=TRUE; END IF;
	IF _where_clause LIKE '%ped.%' THEN 
		_join_individual_pedigree_table=TRUE;
		_join_pedigree_table=TRUE; 
	END IF;
	IF _where_clause LIKE '%ind_ped.%' THEN _join_individual_pedigree_table=TRUE; END IF;
	IF _where_clause LIKE '%ind_dis.%' THEN _join_individual_disease_table=TRUE; END IF;
	IF _where_clause LIKE '%ind_phf.%' THEN _join_individual_phenotypic_feature_table=TRUE; END IF;
	
	---------------------
	-- BUILD THE QUERY --
	---------------------
	_query = '
		select COUNT(DISTINCT var.id)
		from public.variant_table var
		INNER JOIN public.dataset_table dat ON dat.id=var.dataset_id';
			
	IF _join_sample_table THEN
		_query = _query || '
		INNER JOIN public.variant_sample_table var_sam ON var_sam.variant_id=var.id
		INNER JOIN public.sample_w_ontology_terms sam ON sam.id=var_sam.sample_id';
	END IF;
	IF _join_individual_table THEN
		_query = _query || '
		INNER JOIN public.individual_w_ontology_terms ind ON ind.id=sam.individual_id';
	END IF;
	IF _join_individual_pedigree_table THEN
		_query = _query || '
		INNER JOIN public.individual_pedigree_w_ontology_terms ind_ped ON ind_ped.individual_id=ind.id';
	END IF;
	IF _join_pedigree_table THEN
		_query = _query || '
		INNER JOIN public.pedigree_table ped ON ped.stable_id=ind_ped.pedigree_stable_id';
	END IF;
	IF _join_individual_disease_table THEN
		_query = _query || '
		INNER JOIN public.individual_disease_w_ontology_terms ind_dis ON ind_dis.individual_id=ind.id';
	END IF;
	IF _join_individual_phenotypic_feature_table THEN
		_query = _query || '
		INNER JOIN public.individual_phenotypic_feature_w_ontology_terms ind_phf ON ind_phf.individual_id=ind.id';
	END IF;

	_query = _query || _where_clause;

	RAISE NOTICE '_query: %', _query;

	RETURN QUERY EXECUTE _query
	USING _variant_type, _start, _refseq, _reference_bases, _alternate_bases, 
		_reference_genome, _dataset_stable_ids, _end, _start_min, _start_max, _end_min, _end_max, 
		_biosample_stable_id, _individual_stable_id, _gvariant_id;
	-- #1=_variant_type, #2=_start, #3=_refseq, #4=_reference_bases, #5=_alternate_bases, 
	-- #6=_reference_genome, #7=_dataset_stable_ids, #8=_end, #9=_start_min, #10=_start_max, 
	-- #11=_end_min, #12=_end_max, 
	-- #13=_biosample_stable_id, #14=_individual_stable_id, #15=_gvariant_id,
END
$$;


--
-- TOC entry 299 (class 1255 OID 16388)
-- Name: count_individuals(text, integer, integer, integer, integer, integer, integer, character varying, text, text, text, text[], boolean, text, text, integer, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.count_individuals(_variant_type text, _start integer, _start_min integer, _start_max integer, _end integer, _end_min integer, _end_max integer, _refseq character varying, _reference_bases text, _alternate_bases text, _reference_genome text, _dataset_stable_ids text[], _is_authenticated boolean, _biosample_stable_id text, _individual_stable_id text, _gvariant_id integer, _filters text[]) RETURNS TABLE(_num_total_results bigint)
    LANGUAGE plpgsql
    AS $$

-- PRECONDITIONS:
-- _dataset_stable_ids is optional
-- If _is_authenticated=false or _dataset_stable_ids is empty, only PUBLIC datasets will be queried 
--		(regardless there are registered or controlled in _dataset_stable_ids)
-- If _is_authenticated=true, datasets in _dataset_stable_ids will be queried
-- _offset is the number of rows to be skipped
-- _limit is the number of rows to be returned
-- 	If _limit=null & _offset=null, no pagination is applied
-- Expected combinations:
--		* _reference_genome + _refseq + _alternate_bases + _reference_bases + _start
--		* _reference_genome + _refseq + _alternate_bases + (_reference_bases) + _start + _end
--		* _reference_genome + _refseq + (_variant_type) + _start + _end
--		* _reference_genome + _refseq + (_variant_type) + _start_min + _start_max + _end_min + _end_max

DECLARE
	_query text;
	_where_clause text;
	_filters_converted text;
	_join_variant_table bool;
	_join_individual_pedigree_table bool;
	_join_individual_disease_table bool;
	_join_individual_phenotypic_feature_table bool;
	_join_pedigree_table bool;
BEGIN
	_join_variant_table = FALSE;
	_join_pedigree_table = FALSE;
	_join_individual_pedigree_table = FALSE;
	_join_individual_disease_table = FALSE;
	_join_individual_phenotypic_feature_table = FALSE;

	SELECT * INTO _filters_converted
	FROM public.parse_filters(_filters);
	
	SELECT * INTO _where_clause
	FROM public.add_where_clause_conditions(false, _variant_type, _start, _start_min, _start_max, 
											_end, _end_min, _end_max, 
											_refseq, _reference_bases, _alternate_bases, _reference_genome,
											_dataset_stable_ids, _is_authenticated, 
											_biosample_stable_id, _individual_stable_id, _gvariant_id, 
											_filters_converted);
	RAISE NOTICE 'WHERE=%', _where_clause;
	
	-- Aliases used in ontology_term_table
	-- 	'ind'
	-- 	'sam'
	-- 	'ind_ped'
	-- 	'ind_dis'
	-- In the future, we may have filters on variant_table
	
	-- Check what other tables should be joined depending on the filters provided
	IF _where_clause LIKE '%var.%' THEN _join_variant_table=TRUE; END IF;
	IF _where_clause LIKE '%ind_ped.%' THEN _join_individual_pedigree_table=TRUE; END IF;
	IF _where_clause LIKE '%ind_dis.%' THEN _join_individual_disease_table=TRUE; END IF;
	IF _where_clause LIKE '%ind_phf.%' THEN _join_individual_phenotypic_feature_table=TRUE; END IF;
	IF _where_clause LIKE '%ped.%' THEN 
		_join_individual_pedigree_table=TRUE; 
		_join_pedigree_table=TRUE; 
	END IF;
											
	---------------------
	-- BUILD THE QUERY --
	---------------------
	_query = '
		SELECT COUNT(DISTINCT ind.id)
		FROM public.individual_w_ontology_terms ind 
		INNER JOIN public.sample_table sam ON sam.individual_id=ind.id
		INNER JOIN public.dataset_sample_table dataset_sam ON dataset_sam.sample_id=sam.id
		INNER JOIN public.dataset_table dat ON dat.id = dataset_sam.dataset_id
		';
	
	-- Join other tables only if they are necessary
	IF _join_variant_table THEN
		_query = _query || '
		INNER JOIN public.variant_sample_table var_sam ON var_sam.sample_id=sam.id
		INNER JOIN public.variant_table var ON var.id=var_sam.variant_id AND var.dataset_id=dat.id';
	END IF;
	
	IF _join_individual_pedigree_table THEN
		_query = _query || '
		INNER JOIN public.individual_pedigree_w_ontology_terms ind_ped ON ind_ped.individual_id=ind.id';
	END IF;
	
	IF _join_individual_disease_table THEN
		_query = _query || '
		INNER JOIN public.individual_disease_w_ontology_terms ind_dis ON ind_dis.individual_id=ind.id';
	END IF;
	
	IF _join_individual_phenotypic_feature_table THEN
		_query = _query || '
		INNER JOIN public.individual_phenotypic_feature_w_ontology_terms ind_phf ON ind_phf.individual_id=ind.id';
	END IF;
	
	IF _join_pedigree_table THEN
		_query = _query || '
		INNER JOIN public.pedigree_table ped ON ped.stable_id=ind_ped.pedigree_stable_id';
	END IF;

	_query = _query || _where_clause;
	
	RAISE NOTICE '_query: %', _query;

	RETURN QUERY EXECUTE _query
	USING _variant_type, _start, _refseq, _reference_bases, _alternate_bases, 
		_reference_genome, _dataset_stable_ids, _end, _start_min, _start_max, _end_min, _end_max, 
		_biosample_stable_id, _individual_stable_id, _gvariant_id;
	-- #1=_variant_type, #2=_start, #3=_refseq, #4=_reference_bases, #5=_alternate_bases, 
	-- #6=_reference_genome, #7=_dataset_stable_ids, #8=_end, #9=_start_min, #10=_start_max, 
	-- #11=_end_min, #12=_end_max, 
	-- #13=_biosample_stable_id, #14=_individual_stable_id, #15=_gvariant_id,
END
$$;


--
-- TOC entry 298 (class 1255 OID 16390)
-- Name: count_samples(text, integer, integer, integer, integer, integer, integer, character varying, text, text, text, text[], boolean, text, text, integer, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.count_samples(_variant_type text, _start integer, _start_min integer, _start_max integer, _end integer, _end_min integer, _end_max integer, _refseq character varying, _reference_bases text, _alternate_bases text, _reference_genome text, _dataset_stable_ids text[], _is_authenticated boolean, _biosample_stable_id text, _individual_stable_id text, _gvariant_id integer, _filters text[]) RETURNS TABLE(_num_total_samples bigint)
    LANGUAGE plpgsql
    AS $$

-- PRECONDITIONS:
-- _dataset_stable_ids is optional
-- If _is_authenticated=false or _dataset_stable_ids is empty, only PUBLIC datasets will be queried 
--		(regardless there are registered or controlled in _dataset_stable_ids)
-- If _is_authenticated=true, datasets in _dataset_stable_ids will be queried
-- _offset is the number of rows to be skipped
-- _limit is the number of rows to be returned
-- 	If _limit=null & _offset=null, no pagination is applied
-- Expected combinations:
--		* _reference_genome + _refseq + _alternate_bases + _reference_bases + _start
--		* _reference_genome + _refseq + _alternate_bases + (_reference_bases) + _start + _end
--		* _reference_genome + _refseq + (_variant_type) + _start + _end
--		* _reference_genome + _refseq + (_variant_type) + _start_min + _start_max + _end_min + _end_max

DECLARE
	_query text;
	_where_clause text;
	_filters_converted text;
	_join_variant_table bool;
	_join_pedigree_table bool;
	_join_individual_pedigree_table bool;
	_join_individual_disease_table bool;
	_join_individual_phenotypic_feature_table bool;
BEGIN
	_join_variant_table = FALSE;
	_join_pedigree_table = FALSE;
	_join_individual_pedigree_table = FALSE;
	_join_individual_disease_table = FALSE;
	_join_individual_phenotypic_feature_table = FALSE;

	SELECT * INTO _filters_converted
	FROM public.parse_filters(_filters);

	-- Aliases used in ontology_term_table
	-- 	'ind'
	-- 	'sam'
	-- 	'ind_ped'
	-- 	'ind_dis'
	-- In the future, we may have filters on variant_table
	
	-- Check what other tables should be joined depending on the filters provided
	IF _filters_converted LIKE '%var.%' THEN _join_variant_table=TRUE; END IF;
	IF _filters_converted LIKE '%ped.%' THEN 
		_join_individual_pedigree_table=TRUE;
		_join_pedigree_table=TRUE; 
	END IF;
	IF _filters_converted LIKE '%ind_ped.%' THEN _join_individual_pedigree_table=TRUE; END IF;
	IF _filters_converted LIKE '%ind_dis.%' THEN _join_individual_disease_table=TRUE; END IF;
	IF _filters_converted LIKE '%ind_phf.%' THEN _join_individual_phenotypic_feature_table=TRUE; END IF;

	SELECT * INTO _where_clause
	FROM public.add_where_clause_conditions(false, _variant_type, _start, _start_min, _start_max, 
											_end, _end_min, _end_max, 
											_refseq, _reference_bases, _alternate_bases, _reference_genome,
											_dataset_stable_ids, _is_authenticated, 
											_biosample_stable_id, _individual_stable_id, _gvariant_id, 
											_filters_converted);
	RAISE NOTICE 'WHERE=%', _where_clause;
											
	IF _where_clause LIKE '%var.%' THEN _join_variant_table=TRUE; END IF;
	
	---------------------
	-- BUILD THE QUERY --
	---------------------
	_query = '
	SELECT COUNT(DISTINCT sam.id)
	FROM public.sample_w_ontology_terms sam
	INNER JOIN public.individual_w_ontology_terms ind ON ind.id=sam.individual_id
	INNER JOIN public.dataset_sample_table dataset_sam ON dataset_sam.sample_id=sam.id
	INNER JOIN public.dataset_table dat ON dat.id = dataset_sam.dataset_id';
	
	-- Join other tables only if they are necessary	
	IF _join_variant_table THEN
		_query = _query || '
	INNER JOIN public.variant_sample_table var_sam ON var_sam.sample_id=sam.id
	INNER JOIN public.variant_table var ON var.id=var_sam.variant_id';
	END IF;
	
	IF _join_individual_pedigree_table THEN
		_query = _query || '
	INNER JOIN public.individual_pedigree_w_ontology_terms ind_ped ON ind_ped.individual_id=ind.id';
	END IF;
	
	IF _join_pedigree_table THEN
		_query = _query || '
	INNER JOIN public.pedigree_table ped ON ped.stable_id=ind_ped.pedigree_stable_id';
	END IF;
	
	IF _join_individual_disease_table THEN
		_query = _query || '
	INNER JOIN public.individual_disease_w_ontology_terms ind_dis ON ind_dis.individual_id=ind.id';
	END IF;
	
	IF _join_individual_phenotypic_feature_table THEN
		_query = _query || '
	INNER JOIN public.individual_phenotypic_feature_w_ontology_terms ind_phf ON ind_phf.individual_id=ind.id';
	END IF;
	
	RAISE NOTICE '_query: %', _query;

	RETURN QUERY EXECUTE _query
	USING _variant_type, _start, _refseq, _reference_bases, _alternate_bases, 
		_reference_genome, _dataset_stable_ids, _end, _start_min, _start_max, _end_min, _end_max, 
		_biosample_stable_id, _individual_stable_id, _gvariant_id;
	-- #1=_variant_type, #2=_start, #3=_refseq, #4=_reference_bases, #5=_alternate_bases, 
	-- #6=_reference_genome, #7=_dataset_stable_ids, #8=_end, #9=_start_min, #10=_start_max, 
	-- #11=_end_min, #12=_end_max, 
	-- #13=_biosample_stable_id, #14=_individual_stable_id, #15=_gvariant_id
END
$$;


--
-- TOC entry 296 (class 1255 OID 18349)
-- Name: crosstab_variant_annotations_cols(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.crosstab_variant_annotations_cols(source_sql text, category text, OUT variant_id integer, OUT genomic_hgvs_id text[], OUT transcript_hgvs_ids text[], OUT protein_hgvs_ids text[], OUT genomic_regions text[], OUT molecular_effects text[], OUT aminoacid_changes text[], OUT effect_impacts text[], OUT functional_classes text[], OUT codon_changes text[], OUT aminoacid_lengths text[], OUT gene_names text[], OUT transcript_biotypes text[], OUT gene_codings text[], OUT transcript_ids text[], OUT exon_ranks text[], OUT genotypes text[]) RETURNS SETOF record
    LANGUAGE c STABLE STRICT
    AS '$libdir/tablefunc', 'crosstab';


--
-- TOC entry 302 (class 1255 OID 18466)
-- Name: fetch_gvariants(text, integer, integer, integer, integer, integer, integer, text, text, text, text, text, text[], boolean, text, text, integer, text[], integer, integer, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fetch_gvariants(_variant_type text, _start integer, _start_min integer, _start_max integer, _end integer, _end_min integer, _end_max integer, _refseq text, _reference_bases text, _alternate_bases text, _reference_genome text, _include_dataset_responses text, _dataset_stable_ids text[], _is_authenticated boolean, _biosample_stable_id text, _individual_stable_id text, _gvariant_id integer, _filters text[], _offset integer, _limit integer, _requested_schemas text[]) RETURNS SETOF public.fetch_variants_result_type
    LANGUAGE plpgsql
    AS $_$

-- PRECONDITIONS:
-- _dataset_stable_ids is optional
-- If _is_authenticated=false or _dataset_stable_ids is empty, only PUBLIC datasets will be queried 
--		(regardless there are registered or controlled in _dataset_stable_ids)
-- If _is_authenticated=true, datasets in _dataset_stable_ids will be queried
-- _offset is the number of rows to be skipped
-- _limit is the number of rows to be returned
-- 	If _limit=null & _offset=null, no pagination is applied
-- Expected combinations:
--		* _reference_genome + _refseq + _alternate_bases + _reference_bases + _start
--		* _reference_genome + _refseq + _alternate_bases + (_reference_bases) + _start + _end
--		* _reference_genome + _refseq + (_variant_type) + _start + _end
--		* _reference_genome + _refseq + (_variant_type) + _start_min + _start_max + _end_min + _end_max

DECLARE
	_query text;
	_where_clause text;
	_joins_clause text;
	_join_crosstab_clause text;
	_filters_converted text;
	_join_individual_table bool;
	_join_sample_table bool;
	_join_pedigree_table bool;
	_join_individual_pedigree_table bool;
	_join_individual_disease_table bool;
	_join_individual_phenotypic_feature_table bool;
	_only_hit_datasets bool;
	_only_miss_datasets bool;
	_none_dataset bool;
	_all_dataset bool;
	-- Schemas and formats for some fields
	_genomic_features_schema_formats text;
	_variant_resources_schema_formats text;
	_handover_schema_format text;
	_datasets_response_schema_format text;
	_datasets_missing_response_schema_format text;

BEGIN
	_join_individual_table = FALSE;
	_join_sample_table = FALSE;
	_join_pedigree_table = FALSE;
	_join_individual_pedigree_table = FALSE;
	_join_individual_disease_table = FALSE;
	_join_individual_phenotypic_feature_table = FALSE;

	_only_hit_datasets = FALSE;
	_only_miss_datasets = FALSE;
	_none_dataset = FALSE;
	_all_dataset = FALSE;
	
	IF _include_dataset_responses = 'HIT' THEN
		_only_hit_datasets = TRUE;
	END IF;
	IF _include_dataset_responses = 'MISS' THEN
		_only_miss_datasets = TRUE;
	END IF;
	IF _include_dataset_responses = 'NONE' THEN
		_none_dataset = TRUE;
	END IF;
	IF _include_dataset_responses = 'ALL' THEN
		_all_dataset = TRUE;
	END IF;

	SELECT * INTO _filters_converted
	FROM public.parse_filters(_filters);

	SELECT * INTO _where_clause
	FROM public.add_where_clause_conditions(false, _variant_type, _start, _start_min, _start_max, 
											_end, _end_min, _end_max, 
											_refseq, _reference_bases, _alternate_bases, _reference_genome,
											_dataset_stable_ids, _is_authenticated, 
											_biosample_stable_id, _individual_stable_id, _gvariant_id, 
											_filters_converted);
	RAISE NOTICE 'WHERE=%', _where_clause;

	IF _where_clause LIKE '%ind.%' 
		OR _where_clause LIKE '%ped.%'
		OR _where_clause LIKE '%ind_ped.%' 
		OR _where_clause LIKE '%ind_dis.%' 
		OR _where_clause LIKE '%ind_phf.%' 
	THEN 
		_join_sample_table=TRUE;
		_join_individual_table=TRUE; 
	END IF;
	IF _where_clause LIKE '%sam.%' THEN 
		_join_sample_table=TRUE; 
	END IF;
	IF _where_clause LIKE '%ped.%' THEN 
		_join_individual_pedigree_table=TRUE;
		_join_pedigree_table=TRUE; 
	END IF;
	IF _where_clause LIKE '%ind_ped.%' THEN 
		_join_individual_pedigree_table=TRUE; 
	END IF;
	IF _where_clause LIKE '%ind_dis.%' THEN 
		_join_individual_disease_table=TRUE; 
	END IF;
	IF _where_clause LIKE '%ind_phf.%' THEN 
		_join_individual_phenotypic_feature_table=TRUE; 
	END IF;
	
	_joins_clause = '
		INNER JOIN public.dataset_table dat ON dat.id=var.dataset_id';
	IF _join_sample_table THEN
		_joins_clause = _joins_clause || '
		INNER JOIN public.variant_sample_table var_sam ON var_sam.variant_id=var.id
		INNER JOIN public.sample_w_ontology_terms sam ON sam.id=var_sam.sample_id';
	END IF;
	IF _join_individual_table THEN
		_joins_clause = _joins_clause || '
		INNER JOIN public.individual_w_ontology_terms ind ON ind.id=sam.individual_id';
	END IF;
	IF _join_individual_pedigree_table THEN
		_joins_clause = _joins_clause || '
		INNER JOIN public.individual_pedigree_w_ontology_terms ind_ped ON ind_ped.individual_id=ind.id';
	END IF;
	IF _join_pedigree_table THEN
		_joins_clause = _joins_clause || '
		INNER JOIN public.pedigree_table ped ON ped.stable_id=ind_ped.pedigree_stable_id';
	END IF;
	IF _join_individual_disease_table THEN
		_joins_clause = _joins_clause || '
		INNER JOIN public.individual_disease_w_ontology_terms ind_dis ON ind_dis.individual_id=ind.id';
	END IF;
	IF _join_individual_phenotypic_feature_table THEN
		_joins_clause = _joins_clause || '
		INNER JOIN public.individual_phenotypic_feature_w_ontology_terms ind_phf ON ind_phf.individual_id=ind.id';
	END IF;
	
	SELECT * INTO _join_crosstab_clause
	FROM public.build_crosstab_clause(_variant_type, _start, _start_min, _start_max,
									_end, _end_min, _end_max, 
									_refseq, _reference_bases, _alternate_bases, _reference_genome,
									_dataset_stable_ids, _is_authenticated, 
									_biosample_stable_id, _individual_stable_id, _gvariant_id, 
									_offset, _limit,
									_filters_converted, _joins_clause);
	-- Add crosstab query to the joins clause
	_joins_clause = _joins_clause || _join_crosstab_clause;
	
	------------------------------------------
	-- Get the formats according to schemas --
	------------------------------------------
	SELECT COALESCE(_schema_formats, quote_literal('{}')) INTO _genomic_features_schema_formats
	FROM public.find_format(_requested_schemas,'public.variant_table','genomic_features_ontology');

	IF _genomic_features_schema_formats=quote_literal('{}') THEN 
		RAISE EXCEPTION 'Requested schemas not found! %', _requested_schemas; 
	END IF;
	
	SELECT COALESCE(_schema_formats, quote_literal('{}')) INTO _variant_resources_schema_formats
	FROM public.find_format(_requested_schemas,'public.variant_table','variant_resources');
	
	SELECT COALESCE(_schema_formats, quote_literal('{}')) INTO _handover_schema_format
	FROM public.find_format(ARRAY['beacon-default-v2.0.0-draft.2'],'handover','handover');
	
	SELECT COALESCE(_schema_formats, quote_literal('{}')) INTO _datasets_response_schema_format
	FROM public.find_format(ARRAY['beacon-default-v2.0.0-draft.2'],'public.variant_table','datasets_response');
	
	SELECT COALESCE(_schema_formats, quote_literal('{}')) INTO _datasets_missing_response_schema_format
	FROM public.find_format(ARRAY['beacon-default-v2.0.0-draft.2'],'public.variant_table','datasets_missing_response');
	
	---------------------
	-- BUILD THE QUERY --
	---------------------
	_query = '
	SELECT DISTINCT ON (var.variant_id)
		variant_id,
		assembly_id, 
		chromosome, 
		refseq_id, 
		alternative_id, 
		reference, 
		alternate, 
		start, 
		"end", 
		variant_type,
		-- annotations
		aminoacid_changes,
		aminoacid_lengths,
		codon_changes,
		effect_impacts,
		exon_ranks,
		functional_classes,
		gene_codings,
		gene_names,
		genomic_hgvs_id,
		genomic_regions,
		genotypes,
		molecular_effects,
		protein_hgvs_ids,
		transcript_biotypes,
		transcript_hgvs_ids,
		transcript_ids,
		-- calculated columns
		''{}''::jsonb AS genomic_regions_ontology, 
		''{}''::jsonb AS molecular_effects_ontology, 
		COALESCE(jsonb_agg(DISTINCT gf.genomic_features_ontology) FILTER (WHERE gf.genomic_features_ontology IS NOT NULL), ''{}''::jsonb) AS genomic_features_ontology,
		COALESCE(jsonb_agg(DISTINCT gf.ontologies_used) FILTER (WHERE gf.ontologies_used IS NOT NULL), ''{}''::jsonb) AS ontologies_used,
		CASE WHEN ' || _none_dataset || ' 
				THEN ''{}''::jsonb
			WHEN ' || _only_miss_datasets || '
				THEN dat_missing.datasets_missing_response
			WHEN ' || _all_dataset || ' 
				THEN dat_missing.datasets_missing_response || datasets_response.datasets_response
			ELSE datasets_response.datasets_response
		END AS datasets_response
	FROM (
		select var.*,
			ct.*, -- columns from the crosstab
			dat.reference_genome::text AS assembly_id
		FROM public.variant_table var';
	
	_query = _query || _joins_clause || _where_clause;
			
	_query = _query || '
		ORDER BY var.id
		LIMIT $16 OFFSET $17
	) var
	LEFT JOIN LATERAL (
		SELECT ' || _datasets_response_schema_format || '
			AS datasets_response,
			array_agg(DISTINCT dat.id) AS dataset_ids
		FROM public.dataset_table dat 
		LEFT JOIN (
			SELECT 
				dat_hand.dataset_id, ' || _handover_schema_format || '
				 AS dataset_handovers
			FROM public.dataset_handover_table dat_hand
			INNER JOIN public.handover_table hand ON hand.id=dat_hand.handover_id
			GROUP BY dat_hand.dataset_id
		) dat_hand ON dat_hand.dataset_id=dat.id
		WHERE dat.id=var.dataset_id
		GROUP BY var.variant_id
	) datasets_response ON TRUE';

	_query = _query || '
		LEFT JOIN LATERAL (
			SELECT ' || _genomic_features_schema_formats || '
					AS genomic_features_ontology,
				' || _variant_resources_schema_formats || '
					AS ontologies_used
			FROM unnest(var.gene_names, var.transcript_ids) AS t(gene_name, transcript_id)
			join lateral (
				values 
					(t.gene_name, ''gene''), 
					(t.transcript_id, ''transcript'') 
			) as v(gene_or_transcript, label) on true
			LEFT JOIN public.ontology_term_table ot_gen_feat ON ot_gen_feat.target_table=''public.variant_annotation_table'' AND ot_gen_feat.column_name=''genomicFeatures'' AND ot_gen_feat.label=v.label
			LEFT JOIN public.ontology_table ot_ontology ON ot_ontology.id=ot_gen_feat.ontology_id
			LEFT JOIN LATERAL (
				values 
				(ot_ontology.ontology_id, ot_ontology.ontology_name, ot_ontology.namespace_prefix,
				ot_ontology.url, ot_ontology.version, ot_ontology.iri_prefix)
			) AS ot(ontology_id, ontology_name, namespace_prefix, url, version, iri_prefix) ON TRUE
			where v.gene_or_transcript is not null
		) gf ON TRUE
		LEFT JOIN LATERAL (
			VALUES 
			(gf.ontologies_used)
		) AS ontologies(used) ON TRUE';
		
	-- Add missing datasets clause
	_query = _query || '	
	LEFT JOIN LATERAL (
		SELECT ' || _datasets_missing_response_schema_format || '
			AS datasets_missing_response
		FROM public.dataset_table dat 
		WHERE NOT(dat.id  = ANY (datasets_response.dataset_ids))
	) dat_missing ON TRUE';
	
	-- Add group by
	_query = _query || '
	GROUP BY 
		variant_id, 
		assembly_id,
		chromosome, 
		refseq_id, 
		alternative_id, 
		reference, 
		alternate, 
		start, 
		"end", 
		variant_type, 
		variant_cnt, 
		call_cnt, 
		sample_cnt, 
		matching_sample_cnt, 
		frequency, 
		dataset_id, 
		-- annotations
		aminoacid_changes,
		aminoacid_lengths,
		codon_changes,
		effect_impacts,
		exon_ranks,
		functional_classes,
		gene_codings,
		gene_names,
		genomic_hgvs_id,
		genomic_regions,
		genotypes,
		molecular_effects,
		protein_hgvs_ids,
		transcript_biotypes,
		transcript_hgvs_ids,
		transcript_ids,
		gf.genomic_features_ontology,
		gf.ontologies_used,
		datasets_response.datasets_response,
		datasets_response.dataset_ids,
		dat_missing.datasets_missing_response
	ORDER BY 
		var.variant_id';

	RAISE NOTICE '_query: %', _query;

	RETURN QUERY EXECUTE _query
	USING _variant_type, _start, _refseq, _reference_bases, _alternate_bases, 
		_reference_genome, _dataset_stable_ids, _end, _start_min, _start_max, _end_min, _end_max, 
		_biosample_stable_id, _individual_stable_id, _gvariant_id, _limit, _offset;
	-- #1=_variant_type, #2=_start, #3=_refseq, #4=_reference_bases, #5=_alternate_bases, 
	-- #6=_reference_genome, #7=_dataset_stable_ids, #8=_end, #9=_start_min, #10=_start_max, 
	-- #11=_end_min, #12=_end_max, 
	-- #13=_biosample_stable_id, #14=_individual_stable_id, #15=_gvariant_id,
	-- #16=_limit, #17=_offset
END
$_$;


--
-- TOC entry 304 (class 1255 OID 18433)
-- Name: fetch_individuals(text, integer, integer, integer, integer, integer, integer, text, text, text, text, text[], boolean, text, text, integer, text[], integer, integer, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fetch_individuals(_variant_type text, _start integer, _start_min integer, _start_max integer, _end integer, _end_min integer, _end_max integer, _refseq text, _reference_bases text, _alternate_bases text, _reference_genome text, _dataset_stable_ids text[], _is_authenticated boolean, _biosample_stable_id text, _individual_stable_id text, _gvariant_id integer, _filters text[], _offset integer, _limit integer, _requested_schemas text[]) RETURNS SETOF public.fetch_individuals_result_type
    LANGUAGE plpgsql
    AS $_$

-- PRECONDITIONS:
-- _dataset_stable_ids is optional
-- If _is_authenticated=false or _dataset_stable_ids is empty, only PUBLIC datasets will be queried 
--		(regardless there are registered or controlled in _dataset_stable_ids)
-- If _is_authenticated=true, datasets in _dataset_stable_ids will be queried
-- _offset is the number of rows to be skipped
-- _limit is the number of rows to be returned
-- 	If _limit=null & _offset=null, no pagination is applied
-- Expected combinations:
--		* _reference_genome + _refseq + _alternate_bases + _reference_bases + _start
--		* _reference_genome + _refseq + _alternate_bases + (_reference_bases) + _start + _end
--		* _reference_genome + _refseq + (_variant_type) + _start + _end
--		* _reference_genome + _refseq + (_variant_type) + _start_min + _start_max + _end_min + _end_max

DECLARE
	_query text;
	_where_clause text;
	_filters_converted text;
	_join_variant_table bool;
	_join_individual_pedigree_table bool;
	_join_individual_disease_table bool;
	_join_individual_phenotypic_feature_table bool;
	_join_pedigree_table bool;
	-- Schemas and formats for some fields
	_phf_schema_formats text;
	_dis_schema_formats text;
	_ped_schema_formats text;
	_individual_resources_schema_formats text;
	_handover_schema_format text;
BEGIN
	_join_variant_table = FALSE;
	_join_pedigree_table = FALSE;
	_join_individual_pedigree_table = FALSE;
	_join_individual_disease_table = FALSE;
	_join_individual_phenotypic_feature_table = FALSE;

	SELECT * INTO _filters_converted
	FROM public.parse_filters(_filters);
	
	SELECT * INTO _where_clause
	FROM public.add_where_clause_conditions(false, _variant_type, _start, _start_min, _start_max, 
											_end, _end_min, _end_max, 
											_refseq, _reference_bases, _alternate_bases, _reference_genome,
											_dataset_stable_ids, _is_authenticated, 
											_biosample_stable_id, _individual_stable_id, _gvariant_id, 
											_filters_converted);
	RAISE NOTICE 'WHERE=%', _where_clause;
	
	-- Check what other tables should be joined depending on the filters provided
	IF _where_clause LIKE '%var.%' THEN _join_variant_table=TRUE; END IF;
	IF _where_clause LIKE '%ind_ped.%' THEN _join_individual_pedigree_table=TRUE; END IF;
	IF _where_clause LIKE '%ind_dis.%' THEN _join_individual_disease_table=TRUE; END IF;
	IF _where_clause LIKE '%ind_phf.%' THEN _join_individual_phenotypic_feature_table=TRUE; END IF;
	IF _where_clause LIKE '%ped.%' THEN 
		_join_individual_pedigree_table=TRUE; 
		_join_pedigree_table=TRUE; 
	END IF;
	
	---------------------------------
	-- Get the schemas and formats --
	---------------------------------
	SELECT COALESCE(_schema_formats, quote_literal('{}')) INTO _phf_schema_formats
	FROM public.find_format(_requested_schemas,'public.individual_table','phenotypic_features');

	IF _phf_schema_formats=quote_literal('{}') THEN 
		RAISE EXCEPTION 'Requested schemas not found! %', _requested_schemas; 
	END IF;

	SELECT COALESCE(_schema_formats, quote_literal('{}')) INTO _dis_schema_formats
	FROM public.find_format(_requested_schemas,'public.individual_table','diseases');

	IF _dis_schema_formats=quote_literal('{}') THEN 
		RAISE EXCEPTION 'Requested schemas not found! %', _requested_schemas; 
	END IF;
	
	SELECT COALESCE(_schema_formats, quote_literal('{}')) INTO _ped_schema_formats
	FROM public.find_format(_requested_schemas,'public.individual_table','pedigrees');

	IF _ped_schema_formats=quote_literal('{}') THEN 
		RAISE EXCEPTION 'Requested schemas not found! %', _requested_schemas; 
	END IF;
	
	SELECT COALESCE(_schema_formats, quote_literal('{}')) INTO _individual_resources_schema_formats
	FROM public.find_format(_requested_schemas,'public.individual_table','individual_resources');

	SELECT COALESCE(_schema_formats, quote_literal('{}')) INTO _handover_schema_format
	FROM public.find_format(ARRAY['beacon-default-v2.0.0-draft.2'],'handover','handover');
	
	---------------------
	-- BUILD THE QUERY --
	---------------------
	_query = '
		SELECT DISTINCT ON (ind.stable_id)
			ind.stable_id AS individual_id,
			array_agg(DISTINCT dat.stable_id::text) AS dataset_ids,
			ind.taxon_id AS taxon_id,
			ind.taxon_id_ontology AS taxon_id_ontology,
			ind.taxon_id_ontology_label,
			ind.sex AS sex,
			ind.sex_ontology AS sex_ontology,
			ind.ethnicity AS ethnicity,
			ind.ethnicity_ontology AS ethnicity_ontology,
			ind.geographic_origin AS geographic_origin,
			ind.geographic_origin_ontology AS geographic_origin_ontology,
			ind_hand.individual_handovers,
			COALESCE(jsonb_agg(DISTINCT ind_ped2.pedigrees) FILTER (WHERE ind_ped2.pedigrees IS NOT NULL), ''{}''::jsonb) AS pedigrees,
			COALESCE(jsonb_agg(DISTINCT ind_dis2.diseases) FILTER (WHERE ind_dis2.diseases IS NOT NULL), ''{}''::jsonb) AS diseases,
			COALESCE(jsonb_agg(DISTINCT ind_phf2.phenotypic_features) FILTER (WHERE ind_phf2.phenotypic_features IS NOT NULL), ''{}''::jsonb) AS phenotypic_features,
			COALESCE(jsonb_agg(DISTINCT ontologies.used) FILTER (WHERE ontologies.used IS NOT NULL), ''{}''::jsonb) AS ontologies_used,
			-- extra info
			ind.sra_family_id,
			ind.race,
			ind.date_of_birth,
			ind.weight_kg,
			ind.height_cm,
			ind.blood_type,
			COALESCE(ind.medications,''{}''::jsonb) AS medications,
			COALESCE(ind.procedures,''{}''::jsonb) AS procedures,
			COALESCE(array_agg(DISTINCT ind.alternative_id_ontology) FILTER (WHERE ind.alternative_id_ontology IS NOT NULL), ARRAY[]::text[]) AS alternative_ids,
			COALESCE(array_agg(DISTINCT alt_ids_phenopackets.alternative_id_ontology) FILTER (WHERE alt_ids_phenopackets.alternative_id_ontology IS NOT NULL), ARRAY[]::text[]) AS alterntive_ids_phenopackets
		FROM public.individual_w_ontology_terms ind 
		INNER JOIN public.sample_table sam ON sam.individual_id=ind.id
		INNER JOIN public.dataset_sample_table dataset_sam ON dataset_sam.sample_id=sam.id
		INNER JOIN public.dataset_table dat ON dat.id = dataset_sam.dataset_id';
	
	-- Join other tables only if they are necessary
	IF _join_variant_table THEN
		_query = _query || '
		INNER JOIN public.variant_sample_table var_sam ON var_sam.sample_id=sam.id
		INNER JOIN public.variant_table var ON var.id=var_sam.variant_id AND var.dataset_id=dat.id';
	END IF;
	
	IF _join_individual_pedigree_table THEN
		_query = _query || '
		INNER JOIN public.individual_pedigree_w_ontology_terms ind_ped ON ind_ped.individual_id=ind.id';
	END IF;
	
	IF _join_individual_disease_table THEN
		_query = _query || '
		INNER JOIN public.individual_disease_w_ontology_terms ind_dis ON ind_dis.individual_id=ind.id';
	END IF;
	
	IF _join_individual_phenotypic_feature_table THEN
		_query = _query || '
		INNER JOIN public.individual_phenotypic_feature_w_ontology_terms ind_phf ON ind_phf.individual_id=ind.id';
	END IF;
	
	IF _join_pedigree_table THEN
		_query = _query || '
		INNER JOIN public.pedigree_table ped ON ped.stable_id=ind_ped.pedigree_stable_id';
	END IF;
	
	-- Add LEFT JOINs
	_query = _query || '
		LEFT JOIN individual_alternative_id_w_ontology alt_ids_phenopackets ON alt_ids_phenopackets.individual_id=ind.id
		LEFT JOIN ( -- Individual''s handovers
			SELECT hand.individual_id,
				' || _handover_schema_format || ' AS individual_handovers
			FROM individual_handovers hand
			GROUP BY hand.individual_id
		) ind_hand ON ind_hand.individual_id=ind.id
		LEFT JOIN( -- Individual''s pedigrees
			SELECT ind_ped.individual_id,
				' || _ped_schema_formats || ' AS pedigrees
			FROM public.individual_pedigree_w_ontology_terms ind_ped 
		) ind_ped2 ON ind_ped2.individual_id=ind.id
		LEFT JOIN( -- Individual''s diseases
			SELECT ind_dis.individual_id,
				' || _dis_schema_formats || ' AS diseases,
				' || _individual_resources_schema_formats || ' AS ontologies_used
			FROM public.individual_disease_w_ontology_terms ind_dis 
			LEFT JOIN public.ontology_table disease_ontology ON disease_ontology.id=ind_dis.disease_ontology_id
			LEFT JOIN public.ontology_table age_group_ontology ON age_group_ontology.id=ind_dis.age_group_ontology_id
			LEFT JOIN public.ontology_table stage_ontology ON stage_ontology.id=ind_dis.stage_ontology_id
			LEFT JOIN public.ontology_table onset_type_ontology ON onset_type_ontology.id=ind_dis.onset_type_ontology_id
			LEFT JOIN LATERAL (
				values 
				(disease_ontology.ontology_id, disease_ontology.ontology_name, disease_ontology.namespace_prefix,
				disease_ontology.url, disease_ontology.version, disease_ontology.iri_prefix),
				(age_group_ontology.ontology_id, age_group_ontology.ontology_name, age_group_ontology.namespace_prefix,
				age_group_ontology.url, age_group_ontology.version, age_group_ontology.iri_prefix),
				(stage_ontology.ontology_id, stage_ontology.ontology_name, stage_ontology.namespace_prefix,
				stage_ontology.url, stage_ontology.version, stage_ontology.iri_prefix),
				(onset_type_ontology.ontology_id, onset_type_ontology.ontology_name, onset_type_ontology.namespace_prefix,
				onset_type_ontology.url, onset_type_ontology.version, onset_type_ontology.iri_prefix)
			)	AS ot(ontology_id, ontology_name, namespace_prefix, url, version, iri_prefix) ON TRUE
		) ind_dis2 ON ind_dis2.individual_id=ind.id
		LEFT JOIN( -- Individual''s phenotypic features
			SELECT ind_phf.individual_id,
				' || _phf_schema_formats || ' AS phenotypic_features,
				' || _individual_resources_schema_formats || ' AS ontologies_used
			FROM public.individual_phenotypic_feature_w_ontology_terms ind_phf 
			LEFT JOIN public.ontology_table phenotype_ontology ON phenotype_ontology.id=ind_phf.phenotype_ontology_id
			LEFT JOIN public.ontology_table onset_type_ontology ON onset_type_ontology.id=ind_phf.onset_type_ontology_id
			LEFT JOIN public.ontology_table age_group_ontology ON age_group_ontology.id=ind_phf.age_group_ontology_id
			LEFT JOIN public.ontology_table severity_ontology ON severity_ontology.id=ind_phf.severity_ontology_id
			LEFT JOIN LATERAL (
				values 
				(phenotype_ontology.ontology_id, phenotype_ontology.ontology_name, phenotype_ontology.namespace_prefix,
				phenotype_ontology.url, phenotype_ontology.version, phenotype_ontology.iri_prefix),
				(onset_type_ontology.ontology_id, onset_type_ontology.ontology_name, onset_type_ontology.namespace_prefix,
				onset_type_ontology.url, onset_type_ontology.version, age_group_ontology.iri_prefix),
				(age_group_ontology.ontology_id, age_group_ontology.ontology_name, age_group_ontology.namespace_prefix,
				age_group_ontology.url, age_group_ontology.version, age_group_ontology.iri_prefix),
				(severity_ontology.ontology_id, severity_ontology.ontology_name, severity_ontology.namespace_prefix,
				severity_ontology.url, severity_ontology.version, severity_ontology.iri_prefix)
			)	AS ot(ontology_id, ontology_name, namespace_prefix, url, version, iri_prefix) ON TRUE
		) ind_phf2 ON ind_phf2.individual_id=ind.id
		LEFT JOIN LATERAL (
			SELECT ' || _individual_resources_schema_formats || '
				AS ontologies_used
			FROM public.ontology_table ot 
			WHERE ot.id=ind.taxon_ontology_id
			UNION
			SELECT ' || _individual_resources_schema_formats || '
				AS ontologies_used
			FROM public.ontology_table ot 
			WHERE ot.id=ind.sex_ontology_id
			UNION
			SELECT ' || _individual_resources_schema_formats || '
				AS ontologies_used
			FROM public.ontology_table ot 
			WHERE ot.id=alt_ids_phenopackets.alternative_id_ontology_id
		) taxon_sex_alternative_id_ontology ON TRUE
		LEFT JOIN LATERAL (
			VALUES 
			(taxon_sex_alternative_id_ontology.ontologies_used), 
			(ind_dis2.ontologies_used),
			(ind_phf2.ontologies_used)
		) AS ontologies(used) ON TRUE
		';

	_query = _query || _where_clause;
	
	_query = _query || ' 
		GROUP BY ind.stable_id,
			ind.taxon_id,
			ind.taxon_id_ontology,
			ind.taxon_id_ontology_label,
			ind.sex,
			ind.sex_ontology,
			ind.ethnicity,
			ind.ethnicity_ontology,
			ind.geographic_origin,
			ind.geographic_origin_ontology,
			ind_hand.individual_handovers,
			-- extra info
			ind.sra_family_id,
			ind.race,
			ind.date_of_birth,
			ind.weight_kg,
			ind.height_cm,
			ind.blood_type,
			ind.medications,
			ind.procedures
 		ORDER BY ind.stable_id,
 			ind.sex,
 			ind.sex_ontology,
 			ind.ethnicity,
 			ind.ethnicity_ontology,
 			ind.geographic_origin,
 			ind.geographic_origin_ontology,
			ind_hand.individual_handovers,
			-- extra info
			ind.sra_family_id,
			ind.race,
			ind.date_of_birth,
			ind.weight_kg,
			ind.height_cm,
			ind.blood_type,
			ind.medications,
			ind.procedures
 			';
	
	-- Apply pagination
	_query = _query || '
		LIMIT $16 OFFSET $17';

	RAISE NOTICE '_query: %', _query;

	RETURN QUERY EXECUTE _query
	USING _variant_type, _start, _refseq, _reference_bases, _alternate_bases, 
		_reference_genome, _dataset_stable_ids, _end, _start_min, _start_max, _end_min, _end_max, 
		_biosample_stable_id, _individual_stable_id, _gvariant_id, 
		_limit, _offset;
	-- #1=_variant_type, #2=_start, #3=_refseq, #4=_reference_bases, #5=_alternate_bases, 
	-- #6=_reference_genome, #7=_dataset_stable_ids, #8=_end, #9=_start_min, #10=_start_max, 
	-- #11=_end_min, #12=_end_max, 
	-- #13=_biosample_stable_id, #14=_individual_stable_id, #15=_gvariant_id,
	-- #16=_limit, #17=_offset
END
$_$;


--
-- TOC entry 303 (class 1255 OID 18472)
-- Name: fetch_samples(text, integer, integer, integer, integer, integer, integer, text, text, text, text, text[], boolean, text, text, integer, text[], integer, integer, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fetch_samples(_variant_type text, _start integer, _start_min integer, _start_max integer, _end integer, _end_min integer, _end_max integer, _refseq text, _reference_bases text, _alternate_bases text, _reference_genome text, _dataset_stable_ids text[], _is_authenticated boolean, _biosample_stable_id text, _individual_stable_id text, _gvariant_id integer, _filters text[], _offset integer, _limit integer, _requested_schemas text[]) RETURNS SETOF public.fetch_samples_result_type
    LANGUAGE plpgsql
    AS $_$

-- PRECONDITIONS:
-- _dataset_stable_ids is optional
-- If _is_authenticated=false or _dataset_stable_ids is empty, only PUBLIC datasets will be queried 
--		(regardless there are registered or controlled in _dataset_stable_ids)
-- If _is_authenticated=true, datasets in _dataset_stable_ids will be queried
-- _offset is the number of rows to be skipped
-- _limit is the number of rows to be returned
-- 	If _limit=null & _offset=null, no pagination is applied
-- Expected combinations:
--		* _reference_genome + _refseq + _alternate_bases + _reference_bases + _start
--		* _reference_genome + _refseq + _alternate_bases + (_reference_bases) + _start + _end
--		* _reference_genome + _refseq + (_variant_type) + _start + _end
--		* _reference_genome + _refseq + (_variant_type) + _start_min + _start_max + _end_min + _end_max

DECLARE
	_query text;
	_where_clause text;
	_filters_converted text;
	_join_variant_table bool;
	_join_pedigree_table bool;
	_join_individual_pedigree_table bool;
	_join_individual_disease_table bool;
	_join_individual_phenotypic_feature_table bool;
	-- Schemas and formats for some fields
	_origins_schema_names text;
	_origins_schema_formats text;
	_sample_resources_schema_formats text;
	_handover_schema_format text;
BEGIN
	_join_variant_table = FALSE;
	_join_pedigree_table = FALSE;
	_join_individual_pedigree_table = FALSE;
	_join_individual_disease_table = FALSE;
	_join_individual_phenotypic_feature_table = FALSE;

	SELECT * INTO _filters_converted
	FROM public.parse_filters(_filters);

	-- Aliases used in ontology_term_table
	-- 	'ind'
	-- 	'sam'
	-- 	'ind_ped'
	-- 	'ind_dis'
	-- In the future, we may have filters on variant_table
	
	-- Check what other tables should be joined depending on the filters provided
	IF _filters_converted LIKE '%var.%' THEN _join_variant_table=TRUE; END IF;
	IF _filters_converted LIKE '%ped.%' THEN 
		_join_individual_pedigree_table=TRUE;
		_join_pedigree_table=TRUE; 
	END IF;
	IF _filters_converted LIKE '%ind_ped.%' THEN _join_individual_pedigree_table=TRUE; END IF;
	IF _filters_converted LIKE '%ind_dis.%' THEN _join_individual_disease_table=TRUE; END IF;
	IF _filters_converted LIKE '%ind_phf.%' THEN _join_individual_phenotypic_feature_table=TRUE; END IF;

	SELECT * INTO _where_clause
	FROM public.add_where_clause_conditions(false, _variant_type, _start, _start_min, _start_max, 
											_end, _end_min, _end_max, 
											_refseq, _reference_bases, _alternate_bases, _reference_genome,
											_dataset_stable_ids, _is_authenticated, 
											_biosample_stable_id, _individual_stable_id, _gvariant_id, 
											_filters_converted);
	RAISE NOTICE 'WHERE=%', _where_clause;
											
	IF _where_clause LIKE '%var.%' THEN _join_variant_table=TRUE; END IF;
	
	---------------------------------
	-- Get the schemas and formats --
	---------------------------------
	SELECT COALESCE(_schema_names, '-'), COALESCE(_schema_formats, quote_literal('{}')) INTO _origins_schema_names, _origins_schema_formats
	FROM public.find_format(_requested_schemas,'public.sample_table','sample_origins_ontology');
	
	IF _origins_schema_formats='{}' THEN RAISE EXCEPTION 'Requested schemas not found! %', _requested_schemas; END IF;
	
	SELECT COALESCE(_schema_formats, quote_literal('{}')) INTO _sample_resources_schema_formats
	FROM public.find_format(_requested_schemas,'public.sample_table','sample_resources');
	
	SELECT COALESCE(_schema_formats, quote_literal('{}')) INTO _handover_schema_format
	FROM public.find_format(ARRAY['beacon-default-v2.0.0-draft.2'],'handover','handover');
	
	---------------------
	-- BUILD THE QUERY --
	---------------------
	_query = '
	SELECT 
		q.biosample_stable_id,
		q.individual_stable_id,
		q.description,
		q.biosample_status,
		q.biosample_status_ontology,
		q.biosample_status_ontology_label,
		q.individual_age_at_collection,
		q.obtention_procedure,
		q.obtention_procedure_ontology,
		q.obtention_procedure_ontology_label,
		q.tumor_progression,
		q.tumor_progression_ontology,
		q.tumor_progression_ontology_label,
		q.tumor_grade,
		q.tumor_grade_ontology,
		q.tumor_grade_ontology_label,
		q.collection_date,
		q.biosample_handovers,
		q.sample_origins,
		CASE WHEN ' || _origins_schema_names || ' ILIKE ''%phenopacket%'' 
			THEN q.sample_origins_ontology->0 -- for phenopackets format, only return one value
			ELSE q.sample_origins_ontology 
		END as sample_origins_ontology,
		q.ontologies_used,
		q.alternative_ids,
		q.study_id,
		q.bioproject_id,
		q.files
	FROM (
		SELECT DISTINCT ON (sam.stable_id)
			sam.stable_id AS biosample_stable_id,
			ind.stable_id AS individual_stable_id,
			sam.description,
			sam.biosample_status,
			sam.biosample_status_ontology,
			sam.biosample_status_ontology_label,
			sam.individual_age_at_collection,
			sam.obtention_procedure,
			sam.obtention_procedure_ontology,
			sam.obtention_procedure_ontology_label,
			sam.tumor_progression,
			sam.tumor_progression_ontology,
			sam.tumor_progression_ontology_label,
			sam.tumor_grade,
			sam.tumor_grade_ontology,
			sam.tumor_grade_ontology_label,
			sam.collection_date,
			sam_hand.biosample_handovers,
			sam.sample_origins,
			COALESCE(jsonb_agg(DISTINCT sam_origins.sample_origin_descriptors) FILTER (WHERE sam_origins.sample_origin_descriptors IS NOT NULL), ''{}''::jsonb) AS sample_origins_ontology,
			--sam_origins.sample_origin_descriptors AS sample_origins_ontology
			COALESCE(jsonb_agg(DISTINCT ontologies.used) FILTER (WHERE ontologies.used IS NOT NULL), ''{}''::jsonb) AS ontologies_used,
			sam.alternative_ids,
			sam.study_id,
			sam.bioproject_id,
			COALESCE(sam.files,''{}''::jsonb) AS files
		FROM public.sample_w_ontology_terms sam
		INNER JOIN public.individual_w_ontology_terms ind ON ind.id=sam.individual_id
		INNER JOIN public.dataset_sample_table dataset_sam ON dataset_sam.sample_id=sam.id
		INNER JOIN public.dataset_table dat ON dat.id = dataset_sam.dataset_id';
	
	-- Join other tables only if they are necessary	
	IF _join_variant_table THEN
		_query = _query || '
		INNER JOIN public.variant_sample_table var_sam ON var_sam.sample_id=sam.id
		INNER JOIN public.variant_table var ON var.id=var_sam.variant_id';
	END IF;
	
	IF _join_individual_pedigree_table THEN
		_query = _query || '
		INNER JOIN public.individual_pedigree_w_ontology_terms ind_ped ON ind_ped.individual_id=ind.id';
	END IF;
	
	IF _join_pedigree_table THEN
		_query = _query || '
		INNER JOIN public.pedigree_table ped ON ped.stable_id=ind_ped.pedigree_stable_id';
	END IF;
	
	IF _join_individual_disease_table THEN
		_query = _query || '
		INNER JOIN public.individual_disease_w_ontology_terms ind_dis ON ind_dis.individual_id=ind.id';
	END IF;
	
	IF _join_individual_phenotypic_feature_table THEN
		_query = _query || '
		INNER JOIN public.individual_phenotypic_feature_w_ontology_terms ind_phf ON ind_phf.individual_id=ind.id';
	END IF;
	
	-- Add LEFT JOINS
	_query = _query || '
		LEFT JOIN (
			-- Biosample''s handovers
			SELECT sam_hand.sample_id,' || 
				_handover_schema_format || ' AS biosample_handovers
			FROM public.sample_handover_table sam_hand
			LEFT JOIN public.handover_table hand ON hand.id=sam_hand.handover_id
			GROUP BY sam_hand.sample_id
		) sam_hand ON sam_hand.sample_id=ind.id
		LEFT JOIN LATERAL (
			SELECT ' || _origins_schema_formats || '
				AS sample_origin_descriptors,
					' || _sample_resources_schema_formats || '
				AS ontologies_used
			FROM jsonb_array_elements(sam.sample_origins) AS sam_origins(data)
			LEFT JOIN public.ontology_term_table ot_origin_type ON ot_origin_type.target_table=''public.sample_table'' AND ot_origin_type.column_name=''sampleOriginType'' 
					AND lower(ot_origin_type.column_value)=lower(sam_origins.data->>''sampleOriginType'')
			LEFT JOIN public.ontology_term_table ot_origin_detail ON ot_origin_detail.target_table=''public.sample_table'' AND ot_origin_detail.column_name=''sampleOriginDetail'' 
				AND lower(ot_origin_detail.column_value)=lower(sam_origins.data->>''sampleOriginDetail'')
			LEFT JOIN public.ontology_table ot_origin_detail_ontology ON ot_origin_detail_ontology.id=ot_origin_detail.ontology_id
			LEFT JOIN LATERAL (
				values 
				(ot_origin_detail_ontology.ontology_id, ot_origin_detail_ontology.ontology_name, ot_origin_detail_ontology.namespace_prefix,
				ot_origin_detail_ontology.url, ot_origin_detail_ontology.version, ot_origin_detail_ontology.iri_prefix)
			)	AS ot(ontology_id, ontology_name, namespace_prefix, url, version, iri_prefix) ON TRUE
			ORDER BY 
				sam_origins.data->>''sampleOriginType'',
				sam_origins.data->>''sampleOriginDetail''
		)sam_origins ON TRUE
		LEFT JOIN LATERAL (
			VALUES 
			(sam_origins.ontologies_used)
		) AS ontologies(used) ON TRUE';
	
	_query = _query || _where_clause;
	
	_query = _query || ' 
	GROUP BY sam.stable_id,
			ind.stable_id,
			sam.description,
			sam.biosample_status,
			sam.biosample_status_ontology,
			sam.biosample_status_ontology_label,
			sam.individual_age_at_collection,
			sam.obtention_procedure,
			sam.obtention_procedure_ontology,
			sam.obtention_procedure_ontology_label,
			sam.tumor_progression,
			sam.tumor_progression_ontology,
			sam.tumor_progression_ontology_label,
			sam.tumor_grade,
			sam.tumor_grade_ontology,
			sam.tumor_grade_ontology_label,
			sam.collection_date,
			sam_hand.biosample_handovers,
			sam.sample_origins,
			sam.alternative_ids,
			sam.study_id,
			sam.bioproject_id,
			files
	ORDER BY sam.stable_id,
			ind.stable_id,
			sam.description,
			sam.biosample_status,
			sam.biosample_status_ontology,
			sam.individual_age_at_collection,
			sam.obtention_procedure,
			sam.obtention_procedure_ontology,
			sam.tumor_progression,
			sam.tumor_progression_ontology,
			sam.tumor_grade,
			sam.tumor_grade_ontology,
			sam.alternative_ids,
			sam.study_id,
			sam.bioproject_id,
			files';
	
		-- Apply pagination
		_query = _query || '
		LIMIT $16 OFFSET $17
	)q';

	RAISE NOTICE '_query: %', _query;

	RETURN QUERY EXECUTE _query
	USING _variant_type, _start, _refseq, _reference_bases, _alternate_bases, 
		_reference_genome, _dataset_stable_ids, _end, _start_min, _start_max, _end_min, _end_max, 
		_biosample_stable_id, _individual_stable_id, _gvariant_id, _limit, _offset;
	-- #1=_variant_type, #2=_start, #3=_refseq, #4=_reference_bases, #5=_alternate_bases, 
	-- #6=_reference_genome, #7=_dataset_stable_ids, #8=_end, #9=_start_min, #10=_start_max, 
	-- #11=_end_min, #12=_end_max, 
	-- #13=_biosample_stable_id, #14=_individual_stable_id, #15=_gvariant_id
	-- #16=_limit, #17=_offset
END
$_$;


--
-- TOC entry 281 (class 1255 OID 16398)
-- Name: find_format(text[], text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.find_format(_requested_schemas text[], _table_name text, _field_name text, OUT _schema_names text, OUT _schema_formats text) RETURNS record
    LANGUAGE plpgsql
    AS $$

DECLARE
	_schema_names_tmp text;
	_schema_formats_tmp text;
BEGIN

	select string_agg(quote_literal(schema_name), ','), string_agg(format, ',') INTO _schema_names_tmp, _schema_formats_tmp
	from schema_table
	where field_name=_field_name AND table_name=_table_name AND
		CASE WHEN _requested_schemas IS NULL OR COALESCE(array_length(_requested_schemas, 1), 0)=0 
		THEN is_default=true
		ELSE schema_name = ANY(_requested_schemas)
		END;
	
	IF _schema_names_tmp IS NULL THEN
		RAISE NOTICE '_schema_names_tmp is null';
		select string_agg(quote_literal(schema_name), ','), string_agg(format, ',') INTO _schema_names_tmp, _schema_formats_tmp
		from schema_table
		where field_name=_field_name AND table_name=_table_name AND is_default=true;
	END IF;
	
	_schema_names = _schema_names_tmp;
	_schema_formats = _schema_formats_tmp;
END
$$;


--
-- TOC entry 301 (class 1255 OID 16399)
-- Name: parse_filters(text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.parse_filters(_filters text[], OUT _filters_converted text) RETURNS text
    LANGUAGE plpgsql
    AS $$

BEGIN
	-- _filters format: comma separated list of CURIEs
	-- 		Example: NCIT:C46113,NCIT:C17600,GAZ:00001086

	SELECT string_agg(q.my_filter, ' AND ') INTO _filters_converted
	FROM (
		-- Builds regular filter where the term is translated into the value it encodes (e.g. NCIT:C46113 -> ind.sex='female')
		select ot.target_table_alias || '.' || ot.column_name || ot.operator || quote_literal(ot.column_value) as my_filter
		from (
			SELECT trim(split_part(filter_term,':',1)) AS ontology, 
				trim(split_part(filter_term,':',2)) AS term
			FROM unnest(_filters) AS filter_term
		)q
		LEFT JOIN public.ontology_term_table ot ON ot.ontology=q.ontology AND ot.term=q.term
		UNION
		-- Builds numeric filter (e.g. NCIT:C25347<=170 -> ind.height<=170)
		select ot.column_value || q.operator || q.value as my_filter
		from (
			select q.ontology,
				 term2[1] as term,
				unnest(operator) as operator,
				CASE WHEN term2[2] SIMILAR TO 'P[0-9]+Y' THEN date_part('year', term2[2]::interval)::int
					WHEN term2[2] SIMILAR TO '[0-9]+' THEN term2[2]::int
					ELSE null::int
				END as value
			from (
				SELECT trim(split_part(filter_term,':',1)) AS ontology, 
					trim(split_part(filter_term,':',2)) AS term
				FROM unnest(_filters) AS filter_term
			)q,
			regexp_split_to_array(q.term,'>=|<=|=|>|<') as term2,
			regexp_matches(q.term,'>=|<=|=|>|<') AS operator
		)q
		LEFT JOIN public.ontology_term_table ot ON ot.ontology=q.ontology AND ot.term=q.term
		UNION
		-- Builds STRING filter w/o a term (e.g. custom.pedigree_id='ped1' -> ped.stable_id='ped1'
		select ot.column_value || q.operator || q.value as my_filter
		from (
			select trim(q.tokens[1]) AS ontology,
				unnest(operator) as operator,
				trim(q.tokens[2])::text as value
			from (
				SELECT regexp_split_to_array(filter_term,':|=') AS tokens,
					regexp_matches(filter_term,'=|!=') AS operator
				FROM unnest(_filters) AS filter_term
			)q 
		)q
		LEFT JOIN public.ontology_term_table ot ON ot.ontology=q.ontology AND ot.term='-'
		WHERE ot.target_column_type!='ARRAY'
		UNION
		-- Filters on columns of type ARRAY
		SELECT ot.column_value || ' ' || ot.operator 
			|| ' ARRAY[' || string_agg(f.filter_value, ',') 
			|| ']' as my_filter
		FROM (
			SELECT f.filter_split[1] AS ontology,
				CASE WHEN fvalue SIMILAR TO '[0-9]+' THEN fvalue
				ELSE quote_literal(fvalue) 
				END AS filter_value
			FROM (
				SELECT regexp_split_to_array(t.filter_values,'=|!=') AS filter_split
				FROM unnest(_filters) t(filter_values)
			)f,
			unnest(regexp_split_to_array(f.filter_split[2],',')) AS fvalue
		)f
		INNER JOIN public.ontology_term_table ot ON ot.ontology=f.ontology --AND ot.term=f.val
		WHERE ot.target_column_type='ARRAY'
		GROUP BY ot.column_value || ' ' || ot.operator
	)q
	;

END
$$;


--
-- TOC entry 282 (class 1255 OID 16400)
-- Name: query_gvariants(text, integer, integer, integer, integer, integer, integer, character varying, text, text, text, text, text[], boolean, text, text, integer, text[], integer, integer, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.query_gvariants(_variant_type text, _start integer, _start_min integer, _start_max integer, _end integer, _end_min integer, _end_max integer, _refseq character varying, _reference_bases text, _alternate_bases text, _reference_genome text, _include_dataset_responses text, _dataset_stable_ids text[], _is_authenticated boolean, _biosample_stable_id text, _individual_stable_id text, _gvariant_id integer, _filters text[], _offset integer, _limit integer, _requested_schemas text[]) RETURNS TABLE(num_total_results bigint, variant_id integer, assembly_id text, chromosome text, refseq_id text, variant_name text, reference text, alternate text, start integer, "end" integer, variant_type text, genomic_hgvs_id text, transcript_hgvs_ids text[], protein_hgvs_ids text[], genomic_regions text[], genomic_regions_ontology text[], genomic_features_ontology jsonb, molecular_effects text[], molecular_effects_ontology text[], aminoacid_changes text[], ontologies_used jsonb, dataset_response jsonb)
    LANGUAGE plpgsql
    AS $_$

DECLARE
	_num_total_results bigint;
	_query text;
	
BEGIN

	SELECT * INTO _num_total_results
	FROM public.count_gvariants(
		_variant_type, 
		_start, 
		_start_min, 
		_start_max, 
		_end, 
		_end_min, 
		_end_max, 
		_refseq, 
		_reference_bases, 
		_alternate_bases, 
		_reference_genome, 
		_dataset_stable_ids, 
		_is_authenticated, 
		_biosample_stable_id, 
		_individual_stable_id, 
		_gvariant_id, 
		_filters
	);
	
	RAISE NOTICE '_num_total_results= %', _num_total_results;

	_query ='SELECT $1, * 
		FROM public.fetch_gvariants($2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22)';

	RETURN QUERY EXECUTE _query
	USING _num_total_results,
		_variant_type, 
		_start, 
		_start_min, 
		_start_max, 
		_end, 
		_end_min, 
		_end_max, 
		_refseq, 
		_reference_bases, 
		_alternate_bases, 
		_reference_genome, 
		_include_dataset_responses, 
		_dataset_stable_ids, 
		_is_authenticated, 
		_biosample_stable_id, 
		_individual_stable_id, 
		_gvariant_id, 
		_filters, 
		_offset, 
		_limit, 
		_requested_schemas;

END
$_$;


--
-- TOC entry 283 (class 1255 OID 16401)
-- Name: query_individuals(text, integer, integer, integer, integer, integer, integer, character varying, text, text, text, text[], boolean, text, text, integer, text[], integer, integer, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.query_individuals(_variant_type text, _start integer, _start_min integer, _start_max integer, _end integer, _end_min integer, _end_max integer, _refseq character varying, _reference_bases text, _alternate_bases text, _reference_genome text, _dataset_stable_ids text[], _is_authenticated boolean, _biosample_stable_id text, _individual_stable_id text, _gvariant_id integer, _filters text[], _offset integer, _limit integer, _requested_schemas text[]) RETURNS TABLE(num_total_results bigint, individual_stable_id text, dataset_ids text[], taxon_id text, taxon_id_ontology text, taxon_id_ontology_label text, sex text, sex_ontology text, ethnicity text, ethnicity_ontology text, geographic_origin text, geographic_origin_ontology text, handovers jsonb, pedigrees jsonb, diseases jsonb, phenotypic_features jsonb, ontologies_used jsonb, sra_family_id integer, race text, date_of_birth date, weight_kg integer, height_cm integer, blood_type text, medications jsonb, procedures jsonb, alternative_ids text[], alternative_ids_phenopackets text[])
    LANGUAGE plpgsql
    AS $_$

DECLARE
	_num_total_results bigint;
	_query text;
	
BEGIN

	SELECT * INTO _num_total_results
	FROM public.count_individuals(
		_variant_type, 
		_start, 
		_start_min, 
		_start_max, 
		_end, 
		_end_min, 
		_end_max, 
		_refseq, 
		_reference_bases, 
		_alternate_bases, 
		_reference_genome, 
		_dataset_stable_ids, 
		_is_authenticated, 
		_biosample_stable_id, 
		_individual_stable_id, 
		_gvariant_id, 
		_filters
	);
	
	RAISE NOTICE '_num_total_results= %', _num_total_results;

	_query ='SELECT $1, * 
		FROM public.fetch_individuals($2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21)';

	RETURN QUERY EXECUTE _query
	USING _num_total_results,
		_variant_type, 
		_start, 
		_start_min, 
		_start_max, 
		_end, 
		_end_min, 
		_end_max, 
		_refseq, 
		_reference_bases, 
		_alternate_bases, 
		_reference_genome, 
		_dataset_stable_ids, 
		_is_authenticated, 
		_biosample_stable_id, 
		_individual_stable_id, 
		_gvariant_id, 
		_filters, 
		_offset, 
		_limit, 
		_requested_schemas;

END
$_$;


--
-- TOC entry 300 (class 1255 OID 18403)
-- Name: query_samples(text, integer, integer, integer, integer, integer, integer, text, text, text, text, text[], boolean, text, text, integer, text[], integer, integer, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.query_samples(_variant_type text, _start integer, _start_min integer, _start_max integer, _end integer, _end_min integer, _end_max integer, _refseq text, _reference_bases text, _alternate_bases text, _reference_genome text, _dataset_stable_ids text[], _is_authenticated boolean, _biosample_stable_id text, _individual_stable_id text, _gvariant_id integer, _filters text[], _offset integer, _limit integer, _requested_schemas text[]) RETURNS TABLE(biosample_stable_id text, individual_stable_id text, description text, biosample_status text, biosample_status_ontology text, biosample_status_ontology_label text, individual_age_at_collection text, obtention_procedure text, obtention_procedure_ontology text, obtention_procedure_ontology_label text, tumor_progression text, tumor_progression_ontology text, tumor_progression_ontology_label text, tumor_grade text, tumor_grade_ontology text, tumor_grade_ontology_label text, collection_date date, handovers jsonb, sample_origins jsonb, sample_origins_ontology jsonb, ontologies_used jsonb, alternative_ids text[], study_id text, bioproject_id text, files jsonb)
    LANGUAGE plpgsql
    AS $_$

-- PRECONDITIONS:
-- _dataset_stable_ids is optional
-- If _is_authenticated=false or _dataset_stable_ids is empty, only PUBLIC datasets will be queried 
--		(regardless there are registered or controlled in _dataset_stable_ids)
-- If _is_authenticated=true, datasets in _dataset_stable_ids will be queried
-- _offset is the number of rows to be skipped
-- _limit is the number of rows to be returned
-- 	If _limit=null & _offset=null, no pagination is applied
-- Expected combinations:
--		* _reference_genome + _refseq + _alternate_bases + _reference_bases + _start
--		* _reference_genome + _refseq + _alternate_bases + (_reference_bases) + _start + _end
--		* _reference_genome + _refseq + (_variant_type) + _start + _end
--		* _reference_genome + _refseq + (_variant_type) + _start_min + _start_max + _end_min + _end_max

DECLARE
	_query text;
	_where_clause text;
	_filters_converted text;
	_join_variant_table bool;
	_join_pedigree_table bool;
	_join_individual_pedigree_table bool;
	_join_individual_disease_table bool;
	_join_individual_phenotypic_feature_table bool;
	-- Schemas and formats for some fields
	_origins_schema_names text;
	_origins_schema_formats text;
	_sample_resources_schema_names text;
	_sample_resources_schema_formats text;
BEGIN
	_join_variant_table = FALSE;
	_join_pedigree_table = FALSE;
	_join_individual_pedigree_table = FALSE;
	_join_individual_disease_table = FALSE;
	_join_individual_phenotypic_feature_table = FALSE;

	SELECT * INTO _filters_converted
	FROM public.parse_filters(_filters);

	-- Aliases used in ontology_term_table
	-- 	'ind'
	-- 	'sam'
	-- 	'ind_ped'
	-- 	'ind_dis'
	-- In the future, we may have filters on variant_table
	
	-- Check what other tables should be joined depending on the filters provided
	IF _filters_converted LIKE '%var.%' THEN _join_variant_table=TRUE; END IF;
	IF _filters_converted LIKE '%ped.%' THEN 
		_join_individual_pedigree_table=TRUE;
		_join_pedigree_table=TRUE; 
	END IF;
	IF _filters_converted LIKE '%ind_ped.%' THEN _join_individual_pedigree_table=TRUE; END IF;
	IF _filters_converted LIKE '%ind_dis.%' THEN _join_individual_disease_table=TRUE; END IF;
	IF _filters_converted LIKE '%ind_phf.%' THEN _join_individual_phenotypic_feature_table=TRUE; END IF;

	SELECT * INTO _where_clause
	FROM public.add_where_clause_conditions(false, _variant_type, _start, _start_min, _start_max, 
											_end, _end_min, _end_max, 
											_refseq, _reference_bases, _alternate_bases, _reference_genome,
											_dataset_stable_ids, _is_authenticated, 
											_biosample_stable_id, _individual_stable_id, _gvariant_id, 
											_filters_converted);
	RAISE NOTICE 'WHERE=%', _where_clause;
											
	IF _where_clause LIKE '%var.%' THEN _join_variant_table=TRUE; END IF;
	
-- 	RAISE NOTICE 'Parameters:  
-- 		_variant_type=%, 
-- 		_start=%, _start_min=%, _start_max=%, 
-- 		_end=%, _end_min=%, _end_max=%,
-- 		_refseq=%, _reference_bases=%, _alternate_bases=%, _reference_genome=%, 
-- 		_dataset_stable_ids=%, _is_authenticated=%, 
-- 		_filters=%, _filters_converted=%,
-- 		_biosample_stable_id=%, _individual_stable_id=%,
-- 		_limit=%, _offset=%, _join_variant_table=%', 
-- 	_variant_type, _start, _start_min, _start_max, _end, _end_min, _end_max,
-- 	_refseq, _reference_bases, _alternate_bases, _reference_genome, 
-- 	_dataset_stable_ids, _is_authenticated, _filters, _filters_converted, 
-- 	_biosample_stable_id, _individual_stable_id, 
-- 	_limit, _offset, _join_variant_table;
	
	---------------------------------
	-- Get the schemas and formats --
	---------------------------------
	SELECT COALESCE(_schema_names, '-'), COALESCE(_schema_formats, '-') INTO _origins_schema_names, _origins_schema_formats
	FROM public.find_format(_requested_schemas,'public.sample_table','sample_origins_ontology');
	
	IF _origins_schema_names='-' THEN RAISE EXCEPTION 'Requested schemas not found! %', _requested_schemas; END IF;
	
	SELECT COALESCE(_schema_names, '-'), COALESCE(_schema_formats, '-') INTO _sample_resources_schema_names, _sample_resources_schema_formats
	FROM public.find_format(_requested_schemas,'public.sample_table','sample_resources');
	
	IF _sample_resources_schema_names='-' THEN 
		_sample_resources_schema_names = ''; 
		_sample_resources_schema_formats = '{}';
	END IF;
	
	---------------------
	-- BUILD THE QUERY --
	---------------------
	_query = '
	SELECT 
		q.biosample_stable_id,
		q.individual_stable_id,
		q.description,
		q.biosample_status,
		q.biosample_status_ontology,
		q.biosample_status_ontology_label,
		q.individual_age_at_collection,
		q.obtention_procedure,
		q.obtention_procedure_ontology,
		q.obtention_procedure_ontology_label,
		q.tumor_progression,
		q.tumor_progression_ontology,
		q.tumor_progression_ontology_label,
		q.tumor_grade,
		q.tumor_grade_ontology,
		q.tumor_grade_ontology_label,
		q.collection_date,
		q.biosample_handovers,
		q.sample_origins,
		CASE WHEN ' || _origins_schema_names || ' ILIKE ''%phenopacket%'' 
			THEN q.sample_origins_ontology->0 -- for phenopackets format, only return one value
			ELSE q.sample_origins_ontology 
		END as sample_origins_ontology,
		q.ontologies_used,
		q.alternative_ids,
		q.study_id,
		q.bioproject_id,
		q.files
	FROM (
		SELECT DISTINCT ON (sam.stable_id)
			sam.stable_id AS biosample_stable_id,
			ind.stable_id AS individual_stable_id,
			sam.description,
			sam.biosample_status,
			sam.biosample_status_ontology,
			sam.biosample_status_ontology_label,
			sam.individual_age_at_collection,
			sam.obtention_procedure,
			sam.obtention_procedure_ontology,
			sam.obtention_procedure_ontology_label,
			sam.tumor_progression,
			sam.tumor_progression_ontology,
			sam.tumor_progression_ontology_label,
			sam.tumor_grade,
			sam.tumor_grade_ontology,
			sam.tumor_grade_ontology_label,
			sam.collection_date,
			sam_hand.biosample_handovers,
			sam.sample_origins,
			COALESCE(jsonb_agg(DISTINCT sam_origins.sample_origin_descriptors) FILTER (WHERE sam_origins.sample_origin_descriptors IS NOT NULL), ''{}''::jsonb) AS sample_origins_ontology,
			--sam_origins.sample_origin_descriptors AS sample_origins_ontology
			COALESCE(jsonb_agg(DISTINCT ontologies.used) FILTER (WHERE ontologies.used IS NOT NULL), ''{}''::jsonb) AS ontologies_used,
			sam.alternative_ids,
			sam.study_id,
			sam.bioproject_id,
			COALESCE(sam.files,''{}''::jsonb) AS files
		FROM public.sample_w_ontology_terms sam
		INNER JOIN public.individual_w_ontology_terms ind ON ind.id=sam.individual_id
		INNER JOIN public.dataset_sample_table dataset_sam ON dataset_sam.sample_id=sam.id
		INNER JOIN public.dataset_table dat ON dat.id = dataset_sam.dataset_id';
	
	-- Join other tables only if they are necessary	
	IF _join_variant_table THEN
		_query = _query || '
		INNER JOIN public.variant_sample_table var_sam ON var_sam.sample_id=sam.id
		INNER JOIN public.variant_table var ON var.id=var_sam.variant_id';
	END IF;
	
	IF _join_individual_pedigree_table THEN
		_query = _query || '
		INNER JOIN public.individual_pedigree_w_ontology_terms ind_ped ON ind_ped.individual_id=ind.id';
	END IF;
	
	IF _join_pedigree_table THEN
		_query = _query || '
		INNER JOIN public.pedigree_table ped ON ped.stable_id=ind_ped.pedigree_stable_id';
	END IF;
	
	IF _join_individual_disease_table THEN
		_query = _query || '
		INNER JOIN public.individual_disease_w_ontology_terms ind_dis ON ind_dis.individual_id=ind.id';
	END IF;
	
	IF _join_individual_phenotypic_feature_table THEN
		_query = _query || '
		INNER JOIN public.individual_phenotypic_feature_w_ontology_terms ind_phf ON ind_phf.individual_id=ind.id';
	END IF;
	
	-- Add LEFT JOINS
	_query = _query || '
		LEFT JOIN LATERAL(
			-- Biosample''s handovers
			SELECT jsonb_agg(
						jsonb_build_object(
							''handoverType'', jsonb_build_object(
								''id'', hand.type_id,
								''label'', hand.type_label
							),
							''note'', hand.note,
							''url'', hand.url
						)
					) AS biosample_handovers
			FROM public.sample_handover_table sam_hand
			LEFT JOIN public.handover_table hand ON hand.id=sam_hand.handover_id
			WHERE sam_hand.sample_id=ind.id
			GROUP BY sam_hand.sample_id
		) sam_hand ON TRUE
		LEFT JOIN LATERAL (
			SELECT ' || _origins_schema_formats || '
				AS sample_origin_descriptors,
					' ||
					CASE WHEN _sample_resources_schema_formats='{}' 
						THEN quote_literal(_sample_resources_schema_formats) 
						ELSE _sample_resources_schema_formats
					END
					|| '
				AS ontologies_used
			FROM jsonb_array_elements(sam.sample_origins) AS sam_origins(data)
			LEFT JOIN public.ontology_term_table ot_origin_type ON ot_origin_type.target_table=''public.sample_table'' AND ot_origin_type.column_name=''sampleOriginType'' 
					AND lower(ot_origin_type.column_value)=lower(sam_origins.data->>''sampleOriginType'')
			LEFT JOIN public.ontology_term_table ot_origin_detail ON ot_origin_detail.target_table=''public.sample_table'' AND ot_origin_detail.column_name=''sampleOriginDetail'' 
				AND lower(ot_origin_detail.column_value)=lower(sam_origins.data->>''sampleOriginDetail'')
			LEFT JOIN public.ontology_table ot_origin_detail_ontology ON ot_origin_detail_ontology.id=ot_origin_detail.ontology_id
			LEFT JOIN LATERAL (
				values 
				(ot_origin_detail_ontology.ontology_id, ot_origin_detail_ontology.ontology_name, ot_origin_detail_ontology.namespace_prefix,
				ot_origin_detail_ontology.url, ot_origin_detail_ontology.version, ot_origin_detail_ontology.iri_prefix)
			)	AS ot(ontology_id, ontology_name, namespace_prefix, url, version, iri_prefix) ON TRUE
			ORDER BY 
				sam_origins.data->>''sampleOriginType'',
				sam_origins.data->>''sampleOriginDetail''
		)sam_origins ON TRUE
		LEFT JOIN LATERAL (
			VALUES 
			(sam_origins.ontologies_used)
		) AS ontologies(used) ON TRUE';
	
	_query = _query || _where_clause;
	
	_query = _query || ' 
	GROUP BY sam.stable_id,
			ind.stable_id,
			sam.description,
			sam.biosample_status,
			sam.biosample_status_ontology,
			sam.biosample_status_ontology_label,
			sam.individual_age_at_collection,
			sam.obtention_procedure,
			sam.obtention_procedure_ontology,
			sam.obtention_procedure_ontology_label,
			sam.tumor_progression,
			sam.tumor_progression_ontology,
			sam.tumor_progression_ontology_label,
			sam.tumor_grade,
			sam.tumor_grade_ontology,
			sam.tumor_grade_ontology_label,
			sam.collection_date,
			sam_hand.biosample_handovers,
			sam.sample_origins,
			sam.alternative_ids,
			sam.study_id,
			sam.bioproject_id,
			files
	ORDER BY sam.stable_id,
			ind.stable_id,
			sam.description,
			sam.biosample_status,
			sam.biosample_status_ontology,
			sam.individual_age_at_collection,
			sam.obtention_procedure,
			sam.obtention_procedure_ontology,
			sam.tumor_progression,
			sam.tumor_progression_ontology,
			sam.tumor_grade,
			sam.tumor_grade_ontology,
			sam.alternative_ids,
			sam.study_id,
			sam.bioproject_id,
			files
			';
	
		-- Apply pagination
		_query = _query || '
		LIMIT $16 OFFSET $17
	)q';

	RAISE NOTICE '_query: %', _query;

	RETURN QUERY EXECUTE _query
	USING _variant_type, _start, _refseq, _reference_bases, _alternate_bases, 
		_reference_genome, _dataset_stable_ids, _end, _start_min, _start_max, _end_min, _end_max, 
		_biosample_stable_id, _individual_stable_id, _gvariant_id, _limit, _offset;
	-- #1=_variant_type, #2=_start, #3=_refseq, #4=_reference_bases, #5=_alternate_bases, 
	-- #6=_reference_genome, #7=_dataset_stable_ids, #8=_end, #9=_start_min, #10=_start_max, 
	-- #11=_end_min, #12=_end_max, 
	-- #13=_biosample_stable_id, #14=_individual_stable_id, #15=_gvariant_id
	-- #16=_limit, #17=_offset
END
$_$;


--
-- TOC entry 284 (class 1255 OID 16402)
-- Name: query_samples(text, integer, integer, integer, integer, integer, integer, character varying, text, text, text, text[], boolean, text, text, integer, text[], integer, integer, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.query_samples(_variant_type text, _start integer, _start_min integer, _start_max integer, _end integer, _end_min integer, _end_max integer, _refseq character varying, _reference_bases text, _alternate_bases text, _reference_genome text, _dataset_stable_ids text[], _is_authenticated boolean, _biosample_stable_id text, _individual_stable_id text, _gvariant_id integer, _filters text[], _offset integer, _limit integer, _requested_schemas text[]) RETURNS TABLE(num_total_results bigint, biosample_stable_id text, individual_stable_id text, description text, biosample_status text, biosample_status_ontology text, biosample_status_ontology_label text, individual_age_at_collection text, obtention_procedure text, obtention_procedure_ontology text, obtention_procedure_ontology_label text, tumor_progression text, tumor_progression_ontology text, tumor_progression_ontology_label text, tumor_grade text, tumor_grade_ontology text, tumor_grade_ontology_label text, collection_date date, handovers jsonb, sample_origins jsonb, sample_origins_ontology jsonb, ontologies_used jsonb, alternative_ids text[], study_id text, bioproject_id text, files jsonb)
    LANGUAGE plpgsql
    AS $_$

DECLARE
	_num_total_results bigint;
	_query text;
	
BEGIN

	SELECT * INTO _num_total_results
	FROM public.count_samples(
		_variant_type, 
		_start, 
		_start_min, 
		_start_max, 
		_end, 
		_end_min, 
		_end_max, 
		_refseq, 
		_reference_bases, 
		_alternate_bases, 
		_reference_genome, 
		_dataset_stable_ids, 
		_is_authenticated, 
		_biosample_stable_id, 
		_individual_stable_id, 
		_gvariant_id, 
		_filters
	);
	
	RAISE NOTICE '_num_total_results= %', _num_total_results;

	_query ='SELECT $1, * 
		FROM public.fetch_samples($2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21)';

	RETURN QUERY EXECUTE _query
	USING _num_total_results,
		_variant_type, 
		_start, 
		_start_min, 
		_start_max, 
		_end, 
		_end_min, 
		_end_max, 
		_refseq, 
		_reference_bases, 
		_alternate_bases, 
		_reference_genome, 
		_dataset_stable_ids, 
		_is_authenticated, 
		_biosample_stable_id, 
		_individual_stable_id, 
		_gvariant_id, 
		_filters, 
		_offset, 
		_limit, 
		_requested_schemas;

END
$_$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 206 (class 1259 OID 16403)
-- Name: consent_code_category_table; Type: TABLE; Schema: duo; Owner: -
--

CREATE TABLE duo.consent_code_category_table (
    id integer NOT NULL,
    name character varying(11)
);


--
-- TOC entry 207 (class 1259 OID 16406)
-- Name: consent_code_table; Type: TABLE; Schema: duo; Owner: -
--

CREATE TABLE duo.consent_code_table (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    abbr character varying(20) NOT NULL,
    description character varying(400) NOT NULL,
    additional_constraint_required boolean NOT NULL,
    category_id integer NOT NULL
);


--
-- TOC entry 208 (class 1259 OID 16412)
-- Name: consent_code_table_id_seq; Type: SEQUENCE; Schema: duo; Owner: -
--

CREATE SEQUENCE duo.consent_code_table_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3339 (class 0 OID 0)
-- Dependencies: 208
-- Name: consent_code_table_id_seq; Type: SEQUENCE OWNED BY; Schema: duo; Owner: -
--

ALTER SEQUENCE duo.consent_code_table_id_seq OWNED BY duo.consent_code_table.id;


--
-- TOC entry 213 (class 1259 OID 16437)
-- Name: dataset_consent_code_table; Type: TABLE; Schema: duo; Owner: -
--

CREATE TABLE duo.dataset_consent_code_table (
    dataset_id integer NOT NULL,
    consent_code_id integer NOT NULL,
    additional_constraint text,
    description text,
    version text
);


--
-- TOC entry 209 (class 1259 OID 16414)
-- Name: dataset_table; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dataset_table (
    id integer NOT NULL,
    stable_id character varying(50) NOT NULL,
    description character varying(800),
    access_type character varying(10),
    reference_genome character varying(50),
    variant_cnt bigint NOT NULL,
    call_cnt bigint,
    sample_cnt bigint NOT NULL,
    dataset_source text,
    dataset_type text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    name text,
    CONSTRAINT dataset_table_access_type_check CHECK (((access_type)::text = ANY (ARRAY['PUBLIC'::text, 'REGISTERED'::text, 'CONTROLLED'::text])))
);


--
-- TOC entry 210 (class 1259 OID 16421)
-- Name: dataset; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.dataset AS
 SELECT d.id,
    d.stable_id,
    d.name,
    d.description,
    d.access_type,
    d.reference_genome,
    d.variant_cnt,
    d.call_cnt,
    d.sample_cnt,
    d.dataset_source,
    d.dataset_type,
    d.created_at,
    d.updated_at
   FROM public.dataset_table d
  WHERE (((d.access_type)::text = ANY (ARRAY['PUBLIC'::text, 'REGISTERED'::text, 'CONTROLLED'::text])) AND (d.variant_cnt > 0) AND ((d.reference_genome)::text <> ''::text));


--
-- TOC entry 211 (class 1259 OID 16426)
-- Name: dataset_access_level_table; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dataset_access_level_table (
    dataset_id integer NOT NULL,
    parent_field text NOT NULL,
    field text NOT NULL,
    access_level text NOT NULL,
    CONSTRAINT dataset_access_level_table_access_level_check CHECK ((access_level = ANY (ARRAY['NOT_SUPPORTED'::text, 'PUBLIC'::text, 'REGISTERED'::text, 'CONTROLLED'::text])))
);


--
-- TOC entry 212 (class 1259 OID 16433)
-- Name: dataset_access_level; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.dataset_access_level AS
 SELECT dat.stable_id AS dataset_stable_id,
    dal.parent_field,
    dal.field,
    dal.access_level
   FROM (public.dataset_access_level_table dal
     JOIN public.dataset_table dat ON ((dat.id = dal.dataset_id)));


--
-- TOC entry 214 (class 1259 OID 16443)
-- Name: dataset_consent_code; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.dataset_consent_code AS
 SELECT dc.dataset_id,
    cat.name AS category,
    code.abbr AS code,
    code.description,
    dc.additional_constraint,
    dc.description AS additional_description,
    dc.version
   FROM ((duo.dataset_consent_code_table dc
     JOIN duo.consent_code_table code ON ((code.id = dc.consent_code_id)))
     JOIN duo.consent_code_category_table cat ON ((cat.id = code.category_id)))
  ORDER BY dc.dataset_id, cat.id, code.id;


--
-- TOC entry 215 (class 1259 OID 16448)
-- Name: dataset_handover_table; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dataset_handover_table (
    dataset_id integer NOT NULL,
    handover_id integer NOT NULL
);


--
-- TOC entry 216 (class 1259 OID 16451)
-- Name: dataset_sample_table; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dataset_sample_table (
    id integer NOT NULL,
    dataset_id integer NOT NULL,
    sample_id integer NOT NULL
);


--
-- TOC entry 217 (class 1259 OID 16454)
-- Name: dataset_sample_table_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.dataset_sample_table_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3340 (class 0 OID 0)
-- Dependencies: 217
-- Name: dataset_sample_table_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.dataset_sample_table_id_seq OWNED BY public.dataset_sample_table.id;


--
-- TOC entry 218 (class 1259 OID 16456)
-- Name: dataset_table_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.dataset_table_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3341 (class 0 OID 0)
-- Dependencies: 218
-- Name: dataset_table_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.dataset_table_id_seq OWNED BY public.dataset_table.id;


--
-- TOC entry 219 (class 1259 OID 16458)
-- Name: handover_table; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.handover_table (
    id integer NOT NULL,
    type_id text NOT NULL,
    type_label text,
    note text,
    url text NOT NULL
);


--
-- TOC entry 220 (class 1259 OID 16464)
-- Name: handover_table_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.handover_table_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3342 (class 0 OID 0)
-- Dependencies: 220
-- Name: handover_table_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.handover_table_id_seq OWNED BY public.handover_table.id;


--
-- TOC entry 221 (class 1259 OID 16466)
-- Name: individual_table; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.individual_table (
    id integer NOT NULL,
    stable_id text,
    sex text NOT NULL,
    ethnicity text,
    geographic_origin text,
    taxon_id text,
    sra_family_id integer,
    alternative_ids text[],
    race text,
    date_of_birth date,
    weight_kg integer,
    height_cm integer,
    blood_type text,
    medications2 jsonb,
    procedures2 jsonb,
    medications jsonb,
    procedures jsonb,
    CONSTRAINT sex_constraint CHECK ((lower(sex) = ANY (ARRAY['female'::text, 'male'::text, 'other'::text, 'unknown'::text])))
);


--
-- TOC entry 222 (class 1259 OID 16473)
-- Name: individual; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.individual AS
 SELECT individual_table.id,
    individual_table.stable_id,
    individual_table.sex,
    individual_table.ethnicity,
    individual_table.geographic_origin,
    individual_table.taxon_id
   FROM public.individual_table;


--
-- TOC entry 223 (class 1259 OID 16477)
-- Name: individual_alternative_id_table; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.individual_alternative_id_table (
    id integer NOT NULL,
    individual_id integer NOT NULL,
    ontology text NOT NULL,
    term text NOT NULL,
    ontology_id integer
);


--
-- TOC entry 224 (class 1259 OID 16483)
-- Name: individual_alternative_id_table_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.individual_alternative_id_table_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3343 (class 0 OID 0)
-- Dependencies: 224
-- Name: individual_alternative_id_table_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.individual_alternative_id_table_id_seq OWNED BY public.individual_alternative_id_table.id;


--
-- TOC entry 227 (class 1259 OID 16493)
-- Name: ontology_table; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ontology_table (
    id integer NOT NULL,
    ontology_id text NOT NULL,
    ontology_name text NOT NULL,
    namespace_prefix text NOT NULL,
    url text,
    version text NOT NULL,
    iri_prefix text
);


--
-- TOC entry 264 (class 1259 OID 18442)
-- Name: individual_alternative_id_w_ontology; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.individual_alternative_id_w_ontology AS
 SELECT ind_alt.individual_id,
        CASE
            WHEN (ind_alt.id IS NOT NULL) THEN ((ind_alt.ontology || ':'::text) || ind_alt.term)
            ELSE NULL::text
        END AS alternative_id_ontology,
    alt_ontology.id AS alternative_id_ontology_id
   FROM (public.individual_alternative_id_table ind_alt
     JOIN public.ontology_table alt_ontology ON ((alt_ontology.id = ind_alt.ontology_id)));


--
-- TOC entry 225 (class 1259 OID 16485)
-- Name: individual_disease_table; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.individual_disease_table (
    id integer NOT NULL,
    individual_id integer NOT NULL,
    disease_id text NOT NULL,
    age text,
    age_group text,
    stage text,
    family_history boolean,
    date_of_onset date,
    onset_type text,
    severity text
);


--
-- TOC entry 226 (class 1259 OID 16491)
-- Name: individual_disease_table_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.individual_disease_table_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3344 (class 0 OID 0)
-- Dependencies: 226
-- Name: individual_disease_table_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.individual_disease_table_id_seq OWNED BY public.individual_disease_table.id;


--
-- TOC entry 228 (class 1259 OID 16499)
-- Name: ontology_term_table; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ontology_term_table (
    id integer NOT NULL,
    ontology text NOT NULL,
    term text NOT NULL,
    target_table text NOT NULL,
    column_name text NOT NULL,
    column_value text,
    additional_comments text,
    label text,
    target_table_alias text NOT NULL,
    operator text,
    target_column_type text,
    ontology_id integer NOT NULL
);


--
-- TOC entry 229 (class 1259 OID 16505)
-- Name: individual_disease_w_ontology_terms; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.individual_disease_w_ontology_terms AS
 SELECT ind_dis.id,
    ind_dis.individual_id,
    ind_dis.disease_id,
        CASE
            WHEN (ot_disease.id IS NOT NULL) THEN ((ot_disease.ontology || ':'::text) || ot_disease.term)
            ELSE NULL::text
        END AS disease_id_ontology,
        CASE
            WHEN (ot_disease.id IS NOT NULL) THEN ot_disease.label
            ELSE NULL::text
        END AS disease_id_ontology_label,
    disease_ontology.id AS disease_ontology_id,
    ind_dis.age,
    ind_dis.age_group,
        CASE
            WHEN (ot_age_group.id IS NOT NULL) THEN ((ot_age_group.ontology || ':'::text) || ot_age_group.term)
            ELSE NULL::text
        END AS age_group_ontology,
        CASE
            WHEN (ot_age_group.id IS NOT NULL) THEN ot_age_group.label
            ELSE NULL::text
        END AS age_group_ontology_label,
    age_group_ontology.id AS age_group_ontology_id,
    ind_dis.stage,
        CASE
            WHEN (ot_stage.id IS NOT NULL) THEN ((ot_stage.ontology || ':'::text) || ot_stage.term)
            ELSE NULL::text
        END AS stage_ontology,
        CASE
            WHEN (ot_stage.id IS NOT NULL) THEN ot_stage.label
            ELSE NULL::text
        END AS stage_ontology_label,
    stage_ontology.id AS stage_ontology_id,
    ind_dis.family_history,
    ind_dis.date_of_onset,
    ind_dis.onset_type,
        CASE
            WHEN (ot_onset_type.id IS NOT NULL) THEN ((ot_onset_type.ontology || ':'::text) || ot_onset_type.term)
            ELSE NULL::text
        END AS onset_type_ontology,
        CASE
            WHEN (ot_onset_type.id IS NOT NULL) THEN ot_onset_type.label
            ELSE NULL::text
        END AS onset_type_ontology_label,
    onset_type_ontology.id AS onset_type_ontology_id,
    ind_dis.severity,
        CASE
            WHEN (ot_sever.id IS NOT NULL) THEN ((ot_sever.ontology || ':'::text) || ot_sever.term)
            ELSE NULL::text
        END AS severity_ontology,
        CASE
            WHEN (ot_sever.id IS NOT NULL) THEN ((ot_sever.ontology || ':'::text) || ot_sever.term)
            ELSE NULL::text
        END AS severity_ontology_label
   FROM (((((((((public.individual_disease_table ind_dis
     LEFT JOIN public.ontology_term_table ot_disease ON (((ot_disease.target_table = 'public.individual_disease_table'::text) AND (ot_disease.column_name = 'disease_id'::text) AND (lower(ot_disease.column_value) = lower(ind_dis.disease_id)))))
     LEFT JOIN public.ontology_table disease_ontology ON ((disease_ontology.id = ot_disease.ontology_id)))
     LEFT JOIN public.ontology_term_table ot_age_group ON (((ot_age_group.target_table = 'public.individual_disease_table'::text) AND (ot_age_group.column_name = 'age_group'::text) AND (lower(ot_age_group.column_value) = lower(ind_dis.age_group)))))
     LEFT JOIN public.ontology_table age_group_ontology ON ((age_group_ontology.id = ot_age_group.ontology_id)))
     LEFT JOIN public.ontology_term_table ot_stage ON (((ot_stage.target_table = 'public.individual_disease_table'::text) AND (ot_stage.column_name = 'stage'::text) AND (lower(ot_stage.column_value) = lower(ind_dis.stage)))))
     LEFT JOIN public.ontology_table stage_ontology ON ((stage_ontology.id = ot_stage.ontology_id)))
     LEFT JOIN public.ontology_term_table ot_onset_type ON (((ot_onset_type.target_table = 'public.individual_disease_table'::text) AND (ot_onset_type.column_name = 'onset_type'::text) AND (lower(ot_onset_type.column_value) = lower(ind_dis.onset_type)))))
     LEFT JOIN public.ontology_table onset_type_ontology ON ((onset_type_ontology.id = ot_onset_type.ontology_id)))
     LEFT JOIN public.ontology_term_table ot_sever ON (((ot_sever.target_table = 'public.individual_disease_table'::text) AND (ot_sever.column_name = 'severity'::text) AND (lower(ot_sever.column_value) = lower(ind_dis.severity)))));


--
-- TOC entry 230 (class 1259 OID 16510)
-- Name: individual_handover_table; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.individual_handover_table (
    individual_id integer NOT NULL,
    handover_id integer NOT NULL
);


--
-- TOC entry 265 (class 1259 OID 18455)
-- Name: individual_handovers; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.individual_handovers AS
 SELECT ind_hand.individual_id,
    hand.type_id,
    hand.type_label,
    hand.note,
    hand.url
   FROM (public.individual_handover_table ind_hand
     LEFT JOIN public.handover_table hand ON ((hand.id = ind_hand.handover_id)));


--
-- TOC entry 231 (class 1259 OID 16513)
-- Name: individual_pedigree_table; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.individual_pedigree_table (
    individual_id integer NOT NULL,
    pedigree_id integer NOT NULL,
    pedigree_role text NOT NULL,
    number_of_individuals_tested integer,
    disease_id text,
    affected_status text
);


--
-- TOC entry 232 (class 1259 OID 16519)
-- Name: pedigree_table; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pedigree_table (
    id integer NOT NULL,
    stable_id text NOT NULL,
    description text
);


--
-- TOC entry 233 (class 1259 OID 16525)
-- Name: individual_pedigree_w_ontology_terms; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.individual_pedigree_w_ontology_terms AS
 SELECT ind_ped.individual_id,
    ped.stable_id AS pedigree_stable_id,
    ind_ped.disease_id,
        CASE
            WHEN (ot_disease.id IS NOT NULL) THEN ((ot_disease.ontology || ':'::text) || ot_disease.term)
            ELSE NULL::text
        END AS disease_id_ontology,
        CASE
            WHEN (ot_disease.id IS NOT NULL) THEN ot_disease.label
            ELSE NULL::text
        END AS disease_id_ontology_label,
    ind_ped.pedigree_role,
        CASE
            WHEN (ot_role.id IS NOT NULL) THEN ((ot_role.ontology || ':'::text) || ot_role.term)
            ELSE NULL::text
        END AS pedigree_role_ontology,
        CASE
            WHEN (ot_role.id IS NOT NULL) THEN ot_role.label
            ELSE NULL::text
        END AS pedigree_role_ontology_label,
    ind_ped.affected_status,
    ind_ped.number_of_individuals_tested
   FROM (((public.individual_pedigree_table ind_ped
     JOIN public.pedigree_table ped ON ((ped.id = ind_ped.pedigree_id)))
     LEFT JOIN public.ontology_term_table ot_role ON (((ot_role.target_table = 'public.individual_pedigree_table'::text) AND (ot_role.column_name = 'pedigree_role'::text) AND (lower(ot_role.column_value) = lower(ind_ped.pedigree_role)))))
     LEFT JOIN public.ontology_term_table ot_disease ON (((ot_disease.target_table = 'public.individual_pedigree_table'::text) AND (ot_disease.column_name = 'disease_id'::text) AND (lower(ot_disease.column_value) = lower(ind_ped.disease_id)))));


--
-- TOC entry 234 (class 1259 OID 16530)
-- Name: individual_phenotypic_feature_table; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.individual_phenotypic_feature_table (
    id integer NOT NULL,
    individual_id integer NOT NULL,
    phenotype_id text NOT NULL,
    date_of_onset date,
    onset_type text,
    age text,
    age_group text,
    severity text
);


--
-- TOC entry 235 (class 1259 OID 16536)
-- Name: individual_phenotypic_feature_table_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.individual_phenotypic_feature_table_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3345 (class 0 OID 0)
-- Dependencies: 235
-- Name: individual_phenotypic_feature_table_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.individual_phenotypic_feature_table_id_seq OWNED BY public.individual_phenotypic_feature_table.id;


--
-- TOC entry 236 (class 1259 OID 16538)
-- Name: individual_phenotypic_feature_w_ontology_terms; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.individual_phenotypic_feature_w_ontology_terms AS
 SELECT ind_phf.id,
    ind_phf.individual_id,
    ind_phf.phenotype_id,
        CASE
            WHEN (ot_phenotype.id IS NOT NULL) THEN ((ot_phenotype.ontology || ':'::text) || ot_phenotype.term)
            ELSE NULL::text
        END AS phenotype_id_ontology,
        CASE
            WHEN (ot_phenotype.id IS NOT NULL) THEN ot_phenotype.label
            ELSE NULL::text
        END AS phenotype_id_ontology_label,
    phenotype_ontology.id AS phenotype_ontology_id,
    ind_phf.date_of_onset,
    ind_phf.onset_type,
        CASE
            WHEN (ot_onset_type.id IS NOT NULL) THEN ((ot_onset_type.ontology || ':'::text) || ot_onset_type.term)
            ELSE NULL::text
        END AS onset_type_ontology,
        CASE
            WHEN (ot_onset_type.id IS NOT NULL) THEN ot_onset_type.label
            ELSE NULL::text
        END AS onset_type_ontology_label,
    onset_type_ontology.id AS onset_type_ontology_id,
    ind_phf.age,
    ind_phf.age_group,
        CASE
            WHEN (ot_age_group.id IS NOT NULL) THEN ((ot_age_group.ontology || ':'::text) || ot_age_group.term)
            ELSE NULL::text
        END AS age_group_ontology,
        CASE
            WHEN (ot_age_group.id IS NOT NULL) THEN ot_age_group.label
            ELSE NULL::text
        END AS age_group_ontology_label,
    age_group_ontology.id AS age_group_ontology_id,
    ind_phf.severity,
        CASE
            WHEN (ot_severity.id IS NOT NULL) THEN ((ot_severity.ontology || ':'::text) || ot_severity.term)
            ELSE NULL::text
        END AS severity_ontology,
        CASE
            WHEN (ot_severity.id IS NOT NULL) THEN ot_severity.label
            ELSE NULL::text
        END AS severity_ontology_label,
    severity_ontology.id AS severity_ontology_id
   FROM ((((((((public.individual_phenotypic_feature_table ind_phf
     LEFT JOIN public.ontology_term_table ot_phenotype ON (((ot_phenotype.target_table = 'public.individual_phenotypic_feature_table'::text) AND (ot_phenotype.column_name = 'phenotype_id'::text) AND (lower(ot_phenotype.column_value) = lower(ind_phf.phenotype_id)))))
     LEFT JOIN public.ontology_table phenotype_ontology ON ((phenotype_ontology.id = ot_phenotype.ontology_id)))
     LEFT JOIN public.ontology_term_table ot_onset_type ON (((ot_onset_type.target_table = 'public.individual_phenotypic_feature_table'::text) AND (ot_onset_type.column_name = 'onset_type'::text) AND (lower(ot_onset_type.column_value) = lower(ind_phf.onset_type)))))
     LEFT JOIN public.ontology_table onset_type_ontology ON ((onset_type_ontology.id = ot_onset_type.ontology_id)))
     LEFT JOIN public.ontology_term_table ot_age_group ON (((ot_age_group.target_table = 'public.individual_phenotypic_feature_table'::text) AND (ot_age_group.column_name = 'age_group'::text) AND (lower(ot_age_group.column_value) = lower(ind_phf.age_group)))))
     LEFT JOIN public.ontology_table age_group_ontology ON ((age_group_ontology.id = ot_age_group.ontology_id)))
     LEFT JOIN public.ontology_term_table ot_severity ON (((ot_severity.target_table = 'public.individual_phenotypic_feature_table'::text) AND (ot_severity.column_name = 'severity'::text) AND (lower(ot_severity.column_value) = lower(ind_phf.severity)))))
     LEFT JOIN public.ontology_table severity_ontology ON ((severity_ontology.id = ot_severity.ontology_id)));


--
-- TOC entry 237 (class 1259 OID 16543)
-- Name: individual_table_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.individual_table_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3346 (class 0 OID 0)
-- Dependencies: 237
-- Name: individual_table_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.individual_table_id_seq OWNED BY public.individual_table.id;


--
-- TOC entry 238 (class 1259 OID 16545)
-- Name: individual_w_ontology_terms; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.individual_w_ontology_terms AS
 SELECT ind.id,
    ind.stable_id,
    ind.taxon_id,
        CASE
            WHEN (ot_taxon.id IS NOT NULL) THEN ((ot_taxon.ontology || ':'::text) || ot_taxon.term)
            ELSE NULL::text
        END AS taxon_id_ontology,
        CASE
            WHEN (ot_taxon.id IS NOT NULL) THEN ot_taxon.label
            ELSE NULL::text
        END AS taxon_id_ontology_label,
    taxon_ontology.id AS taxon_ontology_id,
    ind.sex,
        CASE
            WHEN (ot_sex.id IS NOT NULL) THEN ((ot_sex.ontology || ':'::text) || ot_sex.term)
            ELSE NULL::text
        END AS sex_ontology,
        CASE
            WHEN (ot_sex.id IS NOT NULL) THEN ot_sex.label
            ELSE NULL::text
        END AS sex_ontology_label,
    sex_ontology.id AS sex_ontology_id,
    ind.ethnicity,
        CASE
            WHEN (ot_ethnicity.id IS NOT NULL) THEN ((ot_ethnicity.ontology || ':'::text) || ot_ethnicity.term)
            ELSE NULL::text
        END AS ethnicity_ontology,
        CASE
            WHEN (ot_ethnicity.id IS NOT NULL) THEN ot_ethnicity.label
            ELSE NULL::text
        END AS ethnicity_ontology_label,
    ind.geographic_origin,
        CASE
            WHEN (ot_geo_origin.id IS NOT NULL) THEN ((ot_geo_origin.ontology || ':'::text) || ot_geo_origin.term)
            ELSE NULL::text
        END AS geographic_origin_ontology,
        CASE
            WHEN (ot_geo_origin.id IS NOT NULL) THEN ot_geo_origin.label
            ELSE NULL::text
        END AS geographic_origin_ontology_label,
    ind.sra_family_id,
    ind.race,
    ind.date_of_birth,
    ind.weight_kg,
    ind.height_cm,
    ind.blood_type,
    ind.medications,
    ind.procedures,
        CASE
            WHEN (ind_alt.id IS NOT NULL) THEN ((ind_alt.ontology || ':'::text) || ind_alt.term)
            ELSE NULL::text
        END AS alternative_id_ontology,
    alt_ontology.id AS alternative_id_ontology_id
   FROM ((((((((public.individual_table ind
     LEFT JOIN public.ontology_term_table ot_taxon ON (((ot_taxon.target_table = 'public.individual_table'::text) AND (ot_taxon.column_name = 'taxon_id'::text) AND (lower(ot_taxon.column_value) = lower(ind.taxon_id)))))
     LEFT JOIN public.ontology_table taxon_ontology ON ((taxon_ontology.id = ot_taxon.ontology_id)))
     LEFT JOIN public.ontology_term_table ot_sex ON (((ot_sex.target_table = 'public.individual_table'::text) AND (ot_sex.column_name = 'sex'::text) AND (lower(ot_sex.column_value) = lower(ind.sex)))))
     LEFT JOIN public.ontology_table sex_ontology ON ((sex_ontology.id = ot_sex.ontology_id)))
     LEFT JOIN public.ontology_term_table ot_ethnicity ON (((ot_ethnicity.target_table = 'public.individual_table'::text) AND (ot_ethnicity.column_name = 'ethnicity'::text) AND (lower(ot_ethnicity.column_value) = lower(ind.ethnicity)))))
     LEFT JOIN public.ontology_term_table ot_geo_origin ON (((ot_geo_origin.target_table = 'public.individual_table'::text) AND (ot_geo_origin.column_name = 'geographic_origin'::text) AND (lower(ot_geo_origin.column_value) = lower(ind.geographic_origin)))))
     LEFT JOIN public.individual_alternative_id_table ind_alt ON ((ind_alt.individual_id = ind.id)))
     LEFT JOIN public.ontology_table alt_ontology ON ((alt_ontology.id = ind_alt.ontology_id)));


--
-- TOC entry 239 (class 1259 OID 16550)
-- Name: ontology_table_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ontology_table_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3347 (class 0 OID 0)
-- Dependencies: 239
-- Name: ontology_table_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ontology_table_id_seq OWNED BY public.ontology_table.id;


--
-- TOC entry 240 (class 1259 OID 16552)
-- Name: ontology_term; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.ontology_term AS
 SELECT ontology_term_table.id,
    ontology_term_table.ontology,
    ontology_term_table.term,
    ontology_term_table.target_table,
    ontology_term_table.column_name,
    ontology_term_table.column_value,
    ontology_term_table.additional_comments,
    ontology_term_table.label,
    ontology_term_table.target_table_alias
   FROM public.ontology_term_table;


--
-- TOC entry 241 (class 1259 OID 16556)
-- Name: ontology_term_table_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ontology_term_table_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3348 (class 0 OID 0)
-- Dependencies: 241
-- Name: ontology_term_table_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ontology_term_table_id_seq OWNED BY public.ontology_term_table.id;


--
-- TOC entry 242 (class 1259 OID 16558)
-- Name: pedigree_table_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pedigree_table_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3349 (class 0 OID 0)
-- Dependencies: 242
-- Name: pedigree_table_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pedigree_table_id_seq OWNED BY public.pedigree_table.id;


--
-- TOC entry 243 (class 1259 OID 16560)
-- Name: sample_handover_table; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sample_handover_table (
    sample_id integer NOT NULL,
    handover_id integer NOT NULL
);


--
-- TOC entry 244 (class 1259 OID 16563)
-- Name: sample_table; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sample_table (
    id integer NOT NULL,
    stable_id text NOT NULL,
    individual_id integer,
    description text,
    biosample_status text,
    individual_age_at_collection text,
    obtention_procedure text,
    tumor_progression text,
    tumor_grade text,
    collection_date date,
    sample_origins jsonb,
    alternative_ids text[],
    study_id text,
    bioproject_id text,
    files jsonb
);


--
-- TOC entry 245 (class 1259 OID 16569)
-- Name: sample_table_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sample_table_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3350 (class 0 OID 0)
-- Dependencies: 245
-- Name: sample_table_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sample_table_id_seq OWNED BY public.sample_table.id;


--
-- TOC entry 246 (class 1259 OID 16571)
-- Name: sample_w_ontology_terms; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.sample_w_ontology_terms AS
 SELECT sam.id,
    sam.stable_id,
    sam.individual_id,
    sam.description,
    sam.biosample_status,
        CASE
            WHEN (ot_status.id IS NOT NULL) THEN ((ot_status.ontology || ':'::text) || ot_status.term)
            ELSE NULL::text
        END AS biosample_status_ontology,
        CASE
            WHEN (ot_status.id IS NOT NULL) THEN ot_status.label
            ELSE NULL::text
        END AS biosample_status_ontology_label,
    sam.individual_age_at_collection,
    sam.obtention_procedure,
        CASE
            WHEN (ot_proc.id IS NOT NULL) THEN ((ot_proc.ontology || ':'::text) || ot_proc.term)
            ELSE NULL::text
        END AS obtention_procedure_ontology,
        CASE
            WHEN (ot_proc.id IS NOT NULL) THEN ot_proc.label
            ELSE NULL::text
        END AS obtention_procedure_ontology_label,
    sam.tumor_progression,
        CASE
            WHEN (ot_t_progress.id IS NOT NULL) THEN ((ot_t_progress.ontology || ':'::text) || ot_t_progress.term)
            ELSE NULL::text
        END AS tumor_progression_ontology,
        CASE
            WHEN (ot_t_progress.id IS NOT NULL) THEN ot_t_progress.label
            ELSE NULL::text
        END AS tumor_progression_ontology_label,
    sam.tumor_grade,
        CASE
            WHEN (ot_t_grade.id IS NOT NULL) THEN ((ot_t_grade.ontology || ':'::text) || ot_t_grade.term)
            ELSE NULL::text
        END AS tumor_grade_ontology,
        CASE
            WHEN (ot_t_grade.id IS NOT NULL) THEN ot_t_grade.label
            ELSE NULL::text
        END AS tumor_grade_ontology_label,
    sam.collection_date,
    sam.sample_origins,
    COALESCE(jsonb_agg(DISTINCT jsonb_build_object(ot_origin_type.column_name,
        CASE
            WHEN (ot_origin_type.id IS NOT NULL) THEN ((ot_origin_type.ontology || ':'::text) || ot_origin_type.term)
            ELSE NULL::text
        END, (ot_origin_type.column_name || 'Label'::text),
        CASE
            WHEN (ot_origin_type.id IS NOT NULL) THEN ot_origin_type.label
            ELSE NULL::text
        END, ot_origin_detail.column_name,
        CASE
            WHEN (ot_origin_detail.id IS NOT NULL) THEN ((ot_origin_detail.ontology || ':'::text) || ot_origin_detail.term)
            ELSE NULL::text
        END, (ot_origin_detail.column_name || 'Label'::text),
        CASE
            WHEN (ot_origin_detail.id IS NOT NULL) THEN ot_origin_detail.label
            ELSE NULL::text
        END)) FILTER (WHERE (ot_origin_type.id IS NOT NULL)), '[]'::jsonb) AS sample_origins_ontology,
    sam.alternative_ids,
    sam.study_id,
    sam.bioproject_id,
    sam.files
   FROM ((((((( SELECT sam_1.id,
            sam_1.stable_id,
            sam_1.individual_id,
            sam_1.description,
            sam_1.biosample_status,
            sam_1.individual_age_at_collection,
            sam_1.obtention_procedure,
            sam_1.tumor_progression,
            sam_1.tumor_grade,
            sam_1.collection_date,
            (sam_origins.data ->> 'sampleOriginType'::text) AS origin_type,
            (sam_origins.data ->> 'sampleOriginDetail'::text) AS origin_detail,
            sam_1.sample_origins,
            sam_1.alternative_ids,
            sam_1.study_id,
            sam_1.bioproject_id,
            sam_1.files
           FROM (public.sample_table sam_1
             LEFT JOIN LATERAL jsonb_array_elements(sam_1.sample_origins) sam_origins(data) ON (true))) sam
     LEFT JOIN public.ontology_term ot_status ON (((ot_status.target_table = 'public.sample_table'::text) AND (ot_status.column_name = 'biosample_status'::text) AND (lower(ot_status.column_value) = lower(sam.biosample_status)))))
     LEFT JOIN public.ontology_term ot_proc ON (((ot_proc.target_table = 'public.sample_table'::text) AND (ot_proc.column_name = 'obtention_procedure'::text) AND (lower(ot_proc.column_value) = lower(sam.obtention_procedure)))))
     LEFT JOIN public.ontology_term ot_t_progress ON (((ot_t_progress.target_table = 'public.sample_table'::text) AND (ot_t_progress.column_name = 'tumor_progression'::text) AND (lower(ot_t_progress.column_value) = lower(sam.tumor_progression)))))
     LEFT JOIN public.ontology_term ot_t_grade ON (((ot_t_grade.target_table = 'public.sample_table'::text) AND (ot_t_grade.column_name = 'tumor_grade'::text) AND (lower(ot_t_grade.column_value) = lower(sam.tumor_grade)))))
     LEFT JOIN public.ontology_term ot_origin_type ON (((ot_origin_type.target_table = 'public.sample_table'::text) AND (ot_origin_type.column_name = 'sampleOriginType'::text) AND (lower(ot_origin_type.column_value) = lower(sam.origin_type)))))
     LEFT JOIN public.ontology_term ot_origin_detail ON (((ot_origin_detail.target_table = 'public.sample_table'::text) AND (ot_origin_detail.column_name = 'sampleOriginDetail'::text) AND (lower(ot_origin_detail.column_value) = lower(sam.origin_detail)))))
  GROUP BY sam.id, sam.stable_id, sam.individual_id, sam.description, sam.biosample_status, ot_status.id, ot_status.ontology, ot_status.label, ot_status.term, sam.individual_age_at_collection, sam.obtention_procedure, ot_proc.id, ot_proc.ontology, ot_proc.label, ot_proc.term, sam.tumor_progression, ot_t_progress.id, ot_t_progress.ontology, ot_t_progress.label, ot_t_progress.term, sam.tumor_grade, ot_t_grade.id, ot_t_grade.ontology, ot_t_grade.label, ot_t_grade.term, sam.collection_date, sam.sample_origins, sam.alternative_ids, sam.study_id, sam.bioproject_id, sam.files;


--
-- TOC entry 247 (class 1259 OID 16576)
-- Name: schema_table; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_table (
    id integer NOT NULL,
    schema_name text NOT NULL,
    table_name text NOT NULL,
    field_name text NOT NULL,
    format text NOT NULL,
    is_default boolean DEFAULT false NOT NULL
);


--
-- TOC entry 248 (class 1259 OID 16583)
-- Name: schema_table_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.schema_table_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3351 (class 0 OID 0)
-- Dependencies: 248
-- Name: schema_table_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.schema_table_id_seq OWNED BY public.schema_table.id;


--
-- TOC entry 259 (class 1259 OID 17473)
-- Name: variant_annotation_table; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.variant_annotation_table (
    variant_id integer NOT NULL,
    annotation_name text NOT NULL,
    annotation_value text[] DEFAULT ARRAY[]::text[]
);


--
-- TOC entry 256 (class 1259 OID 16614)
-- Name: variant_sample_table; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.variant_sample_table (
    variant_id integer NOT NULL,
    sample_id integer NOT NULL,
    frequency numeric,
    zygosity text,
    allele_origin text
);


--
-- TOC entry 257 (class 1259 OID 16620)
-- Name: variant_table; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.variant_table (
    id integer NOT NULL,
    dataset_id integer NOT NULL,
    chromosome text NOT NULL,
    alternative_id text,
    reference text NOT NULL,
    alternate text NOT NULL,
    start integer NOT NULL,
    "end" integer,
    variant_type text,
    sv_length integer,
    variant_cnt integer,
    call_cnt integer,
    sample_cnt integer,
    matching_sample_cnt integer,
    frequency numeric,
    custom_id bigint,
    refseq_id text NOT NULL
);


--
-- TOC entry 258 (class 1259 OID 16626)
-- Name: variant_table_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.variant_table_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3352 (class 0 OID 0)
-- Dependencies: 258
-- Name: variant_table_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.variant_table_id_seq OWNED BY public.variant_table.id;


--
-- TOC entry 249 (class 1259 OID 16585)
-- Name: tmp_sample_table; Type: TABLE; Schema: tmp; Owner: -
--

CREATE TABLE tmp.tmp_sample_table (
    id integer NOT NULL,
    sample_stable_id text NOT NULL,
    dataset_id integer NOT NULL
);


--
-- TOC entry 250 (class 1259 OID 16591)
-- Name: tmp_sample_table_id_seq; Type: SEQUENCE; Schema: tmp; Owner: -
--

CREATE SEQUENCE tmp.tmp_sample_table_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3353 (class 0 OID 0)
-- Dependencies: 250
-- Name: tmp_sample_table_id_seq; Type: SEQUENCE OWNED BY; Schema: tmp; Owner: -
--

ALTER SEQUENCE tmp.tmp_sample_table_id_seq OWNED BY tmp.tmp_sample_table.id;


--
-- TOC entry 251 (class 1259 OID 16593)
-- Name: tmp_variant_table; Type: TABLE; Schema: tmp; Owner: -
--

CREATE TABLE tmp.tmp_variant_table (
    id integer NOT NULL,
    dataset_id integer NOT NULL,
    chromosome character varying(2) NOT NULL,
    variant_id text,
    reference text NOT NULL,
    alternate text NOT NULL,
    start integer NOT NULL,
    "end" integer,
    type character varying(10),
    sv_length integer,
    variant_cnt integer,
    call_cnt integer,
    sample_cnt integer,
    matching_sample_cnt integer,
    frequency numeric,
    genomic_hgvs_id text,
    transcript_hgvs_ids text[],
    protein_hgvs_ids text[],
    genomic_regions text[],
    molecular_effects text[],
    aminoacid_changes text[],
    effect_impacts text[],
    functional_classes text[],
    codon_changes text[],
    aminoacid_lengths text[],
    gene_names text[],
    transcript_biotypes text[],
    gene_codings text[],
    transcript_ids text[],
    exon_ranks text[],
    genotypes text[],
    custom_id bigint NOT NULL
);


--
-- TOC entry 252 (class 1259 OID 16599)
-- Name: tmp_variant_annot_without_duplicates; Type: VIEW; Schema: tmp; Owner: -
--

CREATE VIEW tmp.tmp_variant_annot_without_duplicates AS
 SELECT tmp_variant_table.dataset_id,
    tmp_variant_table.chromosome,
    tmp_variant_table.variant_id,
    tmp_variant_table.reference,
    tmp_variant_table.alternate,
    tmp_variant_table.start,
    tmp_variant_table."end",
    tmp_variant_table.type,
    tmp_variant_table.sv_length,
    tmp_variant_table.variant_cnt,
    tmp_variant_table.call_cnt,
    tmp_variant_table.sample_cnt,
    tmp_variant_table.matching_sample_cnt,
    tmp_variant_table.frequency,
    tmp_variant_table.custom_id,
    ARRAY( SELECT q.v
           FROM ( SELECT t.v
                   FROM unnest(tmp_variant_table.molecular_effects) WITH ORDINALITY t(v, ord)
                  GROUP BY t.v
                  ORDER BY (min(t.ord))) q
          WHERE (q.v <> 'NA'::text)) AS molecular_effects,
    ARRAY( SELECT q.v
           FROM ( SELECT t.v
                   FROM unnest(tmp_variant_table.effect_impacts) WITH ORDINALITY t(v, ord)
                  GROUP BY t.v
                  ORDER BY (min(t.ord))) q
          WHERE (q.v <> 'NA'::text)) AS effect_impacts,
    ARRAY( SELECT q.v
           FROM ( SELECT t.v
                   FROM unnest(tmp_variant_table.functional_classes) WITH ORDINALITY t(v, ord)
                  GROUP BY t.v
                  ORDER BY (min(t.ord))) q
          WHERE (q.v <> 'NA'::text)) AS functional_classes,
    ARRAY( SELECT q.v
           FROM ( SELECT t.v
                   FROM unnest(tmp_variant_table.codon_changes) WITH ORDINALITY t(v, ord)
                  GROUP BY t.v
                  ORDER BY (min(t.ord))) q
          WHERE (q.v <> 'NA'::text)) AS codon_changes,
    ARRAY( SELECT q.v
           FROM ( SELECT t.v
                   FROM unnest(tmp_variant_table.aminoacid_changes) WITH ORDINALITY t(v, ord)
                  GROUP BY t.v
                  ORDER BY (min(t.ord))) q
          WHERE (q.v <> 'NA'::text)) AS aminoacid_changes,
    ARRAY( SELECT (q.v)::integer AS v
           FROM ( SELECT t.v
                   FROM unnest(tmp_variant_table.aminoacid_lengths) WITH ORDINALITY t(v, ord)
                  GROUP BY t.v
                  ORDER BY (min(t.ord))) q
          WHERE (q.v <> 'NA'::text)) AS aminoacid_lengths,
    ARRAY( SELECT q.v
           FROM ( SELECT t.v
                   FROM unnest(tmp_variant_table.gene_names) WITH ORDINALITY t(v, ord)
                  GROUP BY t.v
                  ORDER BY (min(t.ord))) q
          WHERE (q.v <> 'NA'::text)) AS gene_names,
    ARRAY( SELECT q.v
           FROM ( SELECT t.v
                   FROM unnest(tmp_variant_table.transcript_biotypes) WITH ORDINALITY t(v, ord)
                  GROUP BY t.v
                  ORDER BY (min(t.ord))) q
          WHERE (q.v <> 'NA'::text)) AS transcript_biotypes,
    ARRAY( SELECT q.v
           FROM ( SELECT t.v
                   FROM unnest(tmp_variant_table.gene_codings) WITH ORDINALITY t(v, ord)
                  GROUP BY t.v
                  ORDER BY (min(t.ord))) q
          WHERE (q.v <> 'NA'::text)) AS gene_codings,
    ARRAY( SELECT q.v
           FROM ( SELECT t.v
                   FROM unnest(tmp_variant_table.transcript_ids) WITH ORDINALITY t(v, ord)
                  GROUP BY t.v
                  ORDER BY (min(t.ord))) q
          WHERE (q.v <> 'NA'::text)) AS transcript_ids,
    ARRAY( SELECT q.v
           FROM ( SELECT t.v
                   FROM unnest(tmp_variant_table.exon_ranks) WITH ORDINALITY t(v, ord)
                  GROUP BY t.v
                  ORDER BY (min(t.ord))) q
          WHERE (q.v <> 'NA'::text)) AS exon_ranks,
    ARRAY( SELECT q.v
           FROM ( SELECT t.v
                   FROM unnest(tmp_variant_table.genotypes) WITH ORDINALITY t(v, ord)
                  GROUP BY t.v
                  ORDER BY (min(t.ord))) q
          WHERE (q.v <> 'NA'::text)) AS genotypes
   FROM tmp.tmp_variant_table;


--
-- TOC entry 253 (class 1259 OID 16604)
-- Name: tmp_variant_sample_table; Type: TABLE; Schema: tmp; Owner: -
--

CREATE TABLE tmp.tmp_variant_sample_table (
    id integer NOT NULL,
    dataset_id integer NOT NULL,
    sample_ids text[] NOT NULL,
    custom_id integer NOT NULL
);


--
-- TOC entry 254 (class 1259 OID 16610)
-- Name: tmp_variant_sample_table_id_seq; Type: SEQUENCE; Schema: tmp; Owner: -
--

CREATE SEQUENCE tmp.tmp_variant_sample_table_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3354 (class 0 OID 0)
-- Dependencies: 254
-- Name: tmp_variant_sample_table_id_seq; Type: SEQUENCE OWNED BY; Schema: tmp; Owner: -
--

ALTER SEQUENCE tmp.tmp_variant_sample_table_id_seq OWNED BY tmp.tmp_variant_sample_table.id;


--
-- TOC entry 255 (class 1259 OID 16612)
-- Name: tmp_variant_table_id_seq; Type: SEQUENCE; Schema: tmp; Owner: -
--

CREATE SEQUENCE tmp.tmp_variant_table_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3355 (class 0 OID 0)
-- Dependencies: 255
-- Name: tmp_variant_table_id_seq; Type: SEQUENCE OWNED BY; Schema: tmp; Owner: -
--

ALTER SEQUENCE tmp.tmp_variant_table_id_seq OWNED BY tmp.tmp_variant_table.id;


--
-- TOC entry 3083 (class 2604 OID 16628)
-- Name: consent_code_table id; Type: DEFAULT; Schema: duo; Owner: -
--

ALTER TABLE ONLY duo.consent_code_table ALTER COLUMN id SET DEFAULT nextval('duo.consent_code_table_id_seq'::regclass);


--
-- TOC entry 3087 (class 2604 OID 16629)
-- Name: dataset_sample_table id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dataset_sample_table ALTER COLUMN id SET DEFAULT nextval('public.dataset_sample_table_id_seq'::regclass);


--
-- TOC entry 3084 (class 2604 OID 16630)
-- Name: dataset_table id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dataset_table ALTER COLUMN id SET DEFAULT nextval('public.dataset_table_id_seq'::regclass);


--
-- TOC entry 3088 (class 2604 OID 16631)
-- Name: handover_table id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.handover_table ALTER COLUMN id SET DEFAULT nextval('public.handover_table_id_seq'::regclass);


--
-- TOC entry 3091 (class 2604 OID 16632)
-- Name: individual_alternative_id_table id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.individual_alternative_id_table ALTER COLUMN id SET DEFAULT nextval('public.individual_alternative_id_table_id_seq'::regclass);


--
-- TOC entry 3092 (class 2604 OID 16633)
-- Name: individual_disease_table id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.individual_disease_table ALTER COLUMN id SET DEFAULT nextval('public.individual_disease_table_id_seq'::regclass);


--
-- TOC entry 3096 (class 2604 OID 16634)
-- Name: individual_phenotypic_feature_table id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.individual_phenotypic_feature_table ALTER COLUMN id SET DEFAULT nextval('public.individual_phenotypic_feature_table_id_seq'::regclass);


--
-- TOC entry 3089 (class 2604 OID 16635)
-- Name: individual_table id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.individual_table ALTER COLUMN id SET DEFAULT nextval('public.individual_table_id_seq'::regclass);


--
-- TOC entry 3093 (class 2604 OID 16636)
-- Name: ontology_table id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ontology_table ALTER COLUMN id SET DEFAULT nextval('public.ontology_table_id_seq'::regclass);


--
-- TOC entry 3094 (class 2604 OID 16637)
-- Name: ontology_term_table id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ontology_term_table ALTER COLUMN id SET DEFAULT nextval('public.ontology_term_table_id_seq'::regclass);


--
-- TOC entry 3095 (class 2604 OID 16638)
-- Name: pedigree_table id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedigree_table ALTER COLUMN id SET DEFAULT nextval('public.pedigree_table_id_seq'::regclass);


--
-- TOC entry 3097 (class 2604 OID 16639)
-- Name: sample_table id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sample_table ALTER COLUMN id SET DEFAULT nextval('public.sample_table_id_seq'::regclass);


--
-- TOC entry 3099 (class 2604 OID 16640)
-- Name: schema_table id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_table ALTER COLUMN id SET DEFAULT nextval('public.schema_table_id_seq'::regclass);


--
-- TOC entry 3103 (class 2604 OID 16644)
-- Name: variant_table id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.variant_table ALTER COLUMN id SET DEFAULT nextval('public.variant_table_id_seq'::regclass);


--
-- TOC entry 3100 (class 2604 OID 16641)
-- Name: tmp_sample_table id; Type: DEFAULT; Schema: tmp; Owner: -
--

ALTER TABLE ONLY tmp.tmp_sample_table ALTER COLUMN id SET DEFAULT nextval('tmp.tmp_sample_table_id_seq'::regclass);


--
-- TOC entry 3102 (class 2604 OID 16642)
-- Name: tmp_variant_sample_table id; Type: DEFAULT; Schema: tmp; Owner: -
--

ALTER TABLE ONLY tmp.tmp_variant_sample_table ALTER COLUMN id SET DEFAULT nextval('tmp.tmp_variant_sample_table_id_seq'::regclass);


--
-- TOC entry 3101 (class 2604 OID 16643)
-- Name: tmp_variant_table id; Type: DEFAULT; Schema: tmp; Owner: -
--

ALTER TABLE ONLY tmp.tmp_variant_table ALTER COLUMN id SET DEFAULT nextval('tmp.tmp_variant_table_id_seq'::regclass);


--
-- TOC entry 3106 (class 2606 OID 16652)
-- Name: consent_code_category_table consent_code_category_table_pkey; Type: CONSTRAINT; Schema: duo; Owner: -
--

ALTER TABLE ONLY duo.consent_code_category_table
    ADD CONSTRAINT consent_code_category_table_pkey PRIMARY KEY (id);


--
-- TOC entry 3108 (class 2606 OID 16654)
-- Name: consent_code_table consent_code_table_pkey; Type: CONSTRAINT; Schema: duo; Owner: -
--

ALTER TABLE ONLY duo.consent_code_table
    ADD CONSTRAINT consent_code_table_pkey PRIMARY KEY (id);


--
-- TOC entry 3116 (class 2606 OID 16658)
-- Name: dataset_consent_code_table dataset_consent_code_table_pkey; Type: CONSTRAINT; Schema: duo; Owner: -
--

ALTER TABLE ONLY duo.dataset_consent_code_table
    ADD CONSTRAINT dataset_consent_code_table_pkey PRIMARY KEY (dataset_id, consent_code_id);


--
-- TOC entry 3160 (class 2606 OID 16646)
-- Name: variant_sample_table beacon_data_sample_table_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.variant_sample_table
    ADD CONSTRAINT beacon_data_sample_table_pkey PRIMARY KEY (variant_id, sample_id);


--
-- TOC entry 3166 (class 2606 OID 16648)
-- Name: variant_table beacon_data_table_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.variant_table
    ADD CONSTRAINT beacon_data_table_pkey PRIMARY KEY (id);


--
-- TOC entry 3146 (class 2606 OID 16650)
-- Name: sample_table beacon_sample_table_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sample_table
    ADD CONSTRAINT beacon_sample_table_pkey PRIMARY KEY (id);


--
-- TOC entry 3114 (class 2606 OID 16656)
-- Name: dataset_access_level_table dataset_access_level_table_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dataset_access_level_table
    ADD CONSTRAINT dataset_access_level_table_pkey PRIMARY KEY (dataset_id, parent_field, field);


--
-- TOC entry 3118 (class 2606 OID 16660)
-- Name: dataset_sample_table dataset_sample_table_dataset_id_sample_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dataset_sample_table
    ADD CONSTRAINT dataset_sample_table_dataset_id_sample_id_key UNIQUE (dataset_id, sample_id);


--
-- TOC entry 3120 (class 2606 OID 16662)
-- Name: dataset_sample_table dataset_sample_table_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dataset_sample_table
    ADD CONSTRAINT dataset_sample_table_pkey PRIMARY KEY (id);


--
-- TOC entry 3110 (class 2606 OID 16664)
-- Name: dataset_table dataset_table_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dataset_table
    ADD CONSTRAINT dataset_table_pkey PRIMARY KEY (id);


--
-- TOC entry 3122 (class 2606 OID 16666)
-- Name: handover_table handover_table_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.handover_table
    ADD CONSTRAINT handover_table_pkey PRIMARY KEY (id);


--
-- TOC entry 3126 (class 2606 OID 16668)
-- Name: individual_alternative_id_table individual_alternative_id_table_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.individual_alternative_id_table
    ADD CONSTRAINT individual_alternative_id_table_pkey PRIMARY KEY (id);


--
-- TOC entry 3144 (class 2606 OID 16670)
-- Name: individual_phenotypic_feature_table individual_phenotypic_feature_table_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.individual_phenotypic_feature_table
    ADD CONSTRAINT individual_phenotypic_feature_table_pkey PRIMARY KEY (id);


--
-- TOC entry 3130 (class 2606 OID 16672)
-- Name: ontology_table ontology_table_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ontology_table
    ADD CONSTRAINT ontology_table_pkey PRIMARY KEY (id);


--
-- TOC entry 3134 (class 2606 OID 16674)
-- Name: ontology_term_table ontology_term_table_ontology_term_target_table_column_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ontology_term_table
    ADD CONSTRAINT ontology_term_table_ontology_term_target_table_column_name_key UNIQUE (ontology, term, target_table, column_name);


--
-- TOC entry 3136 (class 2606 OID 16676)
-- Name: ontology_term_table ontology_term_table_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ontology_term_table
    ADD CONSTRAINT ontology_term_table_pkey PRIMARY KEY (id);


--
-- TOC entry 3128 (class 2606 OID 16678)
-- Name: individual_disease_table patient_disease_table_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.individual_disease_table
    ADD CONSTRAINT patient_disease_table_pkey PRIMARY KEY (id);


--
-- TOC entry 3138 (class 2606 OID 16680)
-- Name: individual_pedigree_table patient_pedigree_table_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.individual_pedigree_table
    ADD CONSTRAINT patient_pedigree_table_pkey PRIMARY KEY (individual_id, pedigree_id);


--
-- TOC entry 3124 (class 2606 OID 16682)
-- Name: individual_table patient_table_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.individual_table
    ADD CONSTRAINT patient_table_pkey PRIMARY KEY (id);


--
-- TOC entry 3140 (class 2606 OID 16684)
-- Name: pedigree_table pedigree_table_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedigree_table
    ADD CONSTRAINT pedigree_table_pkey PRIMARY KEY (id);


--
-- TOC entry 3142 (class 2606 OID 16686)
-- Name: pedigree_table pedigree_table_stable_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedigree_table
    ADD CONSTRAINT pedigree_table_stable_id_key UNIQUE (stable_id);


--
-- TOC entry 3149 (class 2606 OID 16688)
-- Name: sample_table sample_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sample_table
    ADD CONSTRAINT sample_unique UNIQUE (stable_id);


--
-- TOC entry 3151 (class 2606 OID 16690)
-- Name: schema_table schema_table_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_table
    ADD CONSTRAINT schema_table_pkey PRIMARY KEY (id);


--
-- TOC entry 3153 (class 2606 OID 16692)
-- Name: schema_table schema_table_schema_name_table_name_field_name_is_default_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_table
    ADD CONSTRAINT schema_table_schema_name_table_name_field_name_is_default_key UNIQUE (schema_name, table_name, field_name, is_default);


--
-- TOC entry 3112 (class 2606 OID 16698)
-- Name: dataset_table unique_dataset_stable_id_reference_genome_access_type; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dataset_table
    ADD CONSTRAINT unique_dataset_stable_id_reference_genome_access_type UNIQUE (stable_id, access_type, reference_genome);


--
-- TOC entry 3164 (class 2606 OID 16700)
-- Name: variant_sample_table variant_sample_link_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.variant_sample_table
    ADD CONSTRAINT variant_sample_link_unique UNIQUE (variant_id, sample_id);


--
-- TOC entry 3158 (class 2606 OID 16694)
-- Name: tmp_variant_sample_table tmp_variant_sample_table_pkey; Type: CONSTRAINT; Schema: tmp; Owner: -
--

ALTER TABLE ONLY tmp.tmp_variant_sample_table
    ADD CONSTRAINT tmp_variant_sample_table_pkey PRIMARY KEY (id);


--
-- TOC entry 3156 (class 2606 OID 16696)
-- Name: tmp_variant_table tmp_variant_table_pkey; Type: CONSTRAINT; Schema: tmp; Owner: -
--

ALTER TABLE ONLY tmp.tmp_variant_table
    ADD CONSTRAINT tmp_variant_table_pkey PRIMARY KEY (id);


--
-- TOC entry 3131 (class 1259 OID 16701)
-- Name: idx_ontology_term_table_ontology_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ontology_term_table_ontology_id ON public.ontology_term_table USING btree (ontology_id);


--
-- TOC entry 3132 (class 1259 OID 16702)
-- Name: idx_ontology_term_table_target_table_column_name_label; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ontology_term_table_target_table_column_name_label ON public.ontology_term_table USING btree (target_table, column_name, label);


--
-- TOC entry 3147 (class 1259 OID 16703)
-- Name: idx_sample_table_stable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sample_table_stable_id ON public.sample_table USING btree (stable_id);


--
-- TOC entry 3169 (class 1259 OID 17715)
-- Name: idx_var_annot_variant_id_annotation_name_and_value; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_var_annot_variant_id_annotation_name_and_value ON public.variant_annotation_table USING btree (variant_id, annotation_name, annotation_value);


--
-- TOC entry 3161 (class 1259 OID 16705)
-- Name: idx_variant_sample_table_data_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_variant_sample_table_data_id ON public.variant_sample_table USING btree (variant_id);


--
-- TOC entry 3162 (class 1259 OID 16706)
-- Name: idx_variant_sample_table_sample_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_variant_sample_table_sample_id ON public.variant_sample_table USING btree (sample_id);


--
-- TOC entry 3167 (class 1259 OID 18354)
-- Name: idx_variant_table_region_columns; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_variant_table_region_columns ON public.variant_table USING btree (dataset_id, chromosome, start, "end");


--
-- TOC entry 3168 (class 1259 OID 18355)
-- Name: idx_variant_table_snp_columns; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_variant_table_snp_columns ON public.variant_table USING btree (dataset_id, chromosome, reference, alternate, start);


--
-- TOC entry 3154 (class 1259 OID 16704)
-- Name: idx_tmp_variant_table_variant_columns; Type: INDEX; Schema: tmp; Owner: -
--

CREATE INDEX idx_tmp_variant_table_variant_columns ON tmp.tmp_variant_table USING btree (dataset_id, chromosome, variant_id, reference, alternate, start, type);


--
-- TOC entry 3170 (class 2606 OID 16709)
-- Name: consent_code_table consent_code_table_category_id_fkey; Type: FK CONSTRAINT; Schema: duo; Owner: -
--

ALTER TABLE ONLY duo.consent_code_table
    ADD CONSTRAINT consent_code_table_category_id_fkey FOREIGN KEY (category_id) REFERENCES duo.consent_code_category_table(id);


--
-- TOC entry 3172 (class 2606 OID 16719)
-- Name: dataset_consent_code_table dataset_consent_code_table_consent_code_id_fkey; Type: FK CONSTRAINT; Schema: duo; Owner: -
--

ALTER TABLE ONLY duo.dataset_consent_code_table
    ADD CONSTRAINT dataset_consent_code_table_consent_code_id_fkey FOREIGN KEY (consent_code_id) REFERENCES duo.consent_code_table(id);


--
-- TOC entry 3173 (class 2606 OID 16724)
-- Name: dataset_consent_code_table dataset_consent_code_table_dataset_id_fkey; Type: FK CONSTRAINT; Schema: duo; Owner: -
--

ALTER TABLE ONLY duo.dataset_consent_code_table
    ADD CONSTRAINT dataset_consent_code_table_dataset_id_fkey FOREIGN KEY (dataset_id) REFERENCES public.dataset_table(id);


--
-- TOC entry 3171 (class 2606 OID 16714)
-- Name: dataset_access_level_table dataset_access_level_table_dataset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dataset_access_level_table
    ADD CONSTRAINT dataset_access_level_table_dataset_id_fkey FOREIGN KEY (dataset_id) REFERENCES public.dataset_table(id);


--
-- TOC entry 3174 (class 2606 OID 16729)
-- Name: dataset_handover_table dataset_handover_table_dataset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dataset_handover_table
    ADD CONSTRAINT dataset_handover_table_dataset_id_fkey FOREIGN KEY (dataset_id) REFERENCES public.dataset_table(id);


--
-- TOC entry 3175 (class 2606 OID 16734)
-- Name: dataset_handover_table dataset_handover_table_handover_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dataset_handover_table
    ADD CONSTRAINT dataset_handover_table_handover_id_fkey FOREIGN KEY (handover_id) REFERENCES public.handover_table(id);


--
-- TOC entry 3176 (class 2606 OID 16739)
-- Name: dataset_sample_table dataset_sample_table_dataset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dataset_sample_table
    ADD CONSTRAINT dataset_sample_table_dataset_id_fkey FOREIGN KEY (dataset_id) REFERENCES public.dataset_table(id);


--
-- TOC entry 3177 (class 2606 OID 16744)
-- Name: dataset_sample_table dataset_sample_table_sample_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dataset_sample_table
    ADD CONSTRAINT dataset_sample_table_sample_id_fkey FOREIGN KEY (sample_id) REFERENCES public.sample_table(id);


--
-- TOC entry 3178 (class 2606 OID 16749)
-- Name: individual_alternative_id_table individual_alternative_id_table_individual_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.individual_alternative_id_table
    ADD CONSTRAINT individual_alternative_id_table_individual_id_fkey FOREIGN KEY (individual_id) REFERENCES public.individual_table(id);


--
-- TOC entry 3179 (class 2606 OID 16754)
-- Name: individual_alternative_id_table individual_alternative_id_table_ontology_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.individual_alternative_id_table
    ADD CONSTRAINT individual_alternative_id_table_ontology_id_fkey FOREIGN KEY (ontology_id) REFERENCES public.ontology_table(id);


--
-- TOC entry 3182 (class 2606 OID 16759)
-- Name: individual_handover_table individual_handover_table_handover_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.individual_handover_table
    ADD CONSTRAINT individual_handover_table_handover_id_fkey FOREIGN KEY (handover_id) REFERENCES public.handover_table(id);


--
-- TOC entry 3183 (class 2606 OID 16764)
-- Name: individual_handover_table individual_handover_table_individual_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.individual_handover_table
    ADD CONSTRAINT individual_handover_table_individual_id_fkey FOREIGN KEY (individual_id) REFERENCES public.individual_table(id);


--
-- TOC entry 3186 (class 2606 OID 16769)
-- Name: individual_phenotypic_feature_table individual_phenotypic_feature_table_individual_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.individual_phenotypic_feature_table
    ADD CONSTRAINT individual_phenotypic_feature_table_individual_id_fkey FOREIGN KEY (individual_id) REFERENCES public.individual_table(id);


--
-- TOC entry 3181 (class 2606 OID 16774)
-- Name: ontology_term_table ontology_term_table_ontology_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ontology_term_table
    ADD CONSTRAINT ontology_term_table_ontology_id_fkey FOREIGN KEY (ontology_id) REFERENCES public.ontology_table(id);


--
-- TOC entry 3180 (class 2606 OID 16779)
-- Name: individual_disease_table patient_disease_table_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.individual_disease_table
    ADD CONSTRAINT patient_disease_table_patient_id_fkey FOREIGN KEY (individual_id) REFERENCES public.individual_table(id);


--
-- TOC entry 3189 (class 2606 OID 16784)
-- Name: sample_table patient_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sample_table
    ADD CONSTRAINT patient_id FOREIGN KEY (individual_id) REFERENCES public.individual_table(id);


--
-- TOC entry 3184 (class 2606 OID 16789)
-- Name: individual_pedigree_table patient_pedigree_table_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.individual_pedigree_table
    ADD CONSTRAINT patient_pedigree_table_patient_id_fkey FOREIGN KEY (individual_id) REFERENCES public.individual_table(id);


--
-- TOC entry 3185 (class 2606 OID 16794)
-- Name: individual_pedigree_table patient_pedigree_table_pedigree_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.individual_pedigree_table
    ADD CONSTRAINT patient_pedigree_table_pedigree_id_fkey FOREIGN KEY (pedigree_id) REFERENCES public.pedigree_table(id);


--
-- TOC entry 3187 (class 2606 OID 16799)
-- Name: sample_handover_table sample_handover_table_handover_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sample_handover_table
    ADD CONSTRAINT sample_handover_table_handover_id_fkey FOREIGN KEY (handover_id) REFERENCES public.handover_table(id);


--
-- TOC entry 3188 (class 2606 OID 16804)
-- Name: sample_handover_table sample_handover_table_sample_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sample_handover_table
    ADD CONSTRAINT sample_handover_table_sample_id_fkey FOREIGN KEY (sample_id) REFERENCES public.sample_table(id);


--
-- TOC entry 3193 (class 2606 OID 17480)
-- Name: variant_annotation_table variant_annotation_table_variant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.variant_annotation_table
    ADD CONSTRAINT variant_annotation_table_variant_id_fkey FOREIGN KEY (variant_id) REFERENCES public.variant_table(id);


--
-- TOC entry 3192 (class 2606 OID 16819)
-- Name: variant_table variant_table_dataset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.variant_table
    ADD CONSTRAINT variant_table_dataset_id_fkey FOREIGN KEY (dataset_id) REFERENCES public.dataset_table(id);


--
-- TOC entry 3190 (class 2606 OID 16809)
-- Name: tmp_sample_table tmp_sample_table_dataset_id_fkey; Type: FK CONSTRAINT; Schema: tmp; Owner: -
--

ALTER TABLE ONLY tmp.tmp_sample_table
    ADD CONSTRAINT tmp_sample_table_dataset_id_fkey FOREIGN KEY (dataset_id) REFERENCES public.dataset_table(id);


--
-- TOC entry 3191 (class 2606 OID 16814)
-- Name: tmp_variant_table tmp_variant_table_dataset_id_fkey; Type: FK CONSTRAINT; Schema: tmp; Owner: -
--

ALTER TABLE ONLY tmp.tmp_variant_table
    ADD CONSTRAINT tmp_variant_table_dataset_id_fkey FOREIGN KEY (dataset_id) REFERENCES public.dataset_table(id);


-- Completed on 2021-01-28 11:35:02 CET

--
-- PostgreSQL database dump complete
--


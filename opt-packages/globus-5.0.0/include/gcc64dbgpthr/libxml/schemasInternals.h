/*
 * Summary: internal interfaces for XML Schemas
 * Description: internal interfaces for the XML Schemas handling
 *              and schema validity checking
 *
 * Copy: See Copyright for the status of this software.
 *
 * Author: Daniel Veillard
 */


#ifndef __XML_SCHEMA_INTERNALS_H__
#define __XML_SCHEMA_INTERNALS_H__

#include <libxml/xmlversion.h>

#ifdef LIBXML_SCHEMAS_ENABLED

#include <libxml/xmlregexp.h>
#include <libxml/hash.h>
#include <libxml/dict.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
    XML_SCHEMAS_UNKNOWN = 0,
    XML_SCHEMAS_STRING,
    XML_SCHEMAS_NORMSTRING,
    XML_SCHEMAS_DECIMAL,
    XML_SCHEMAS_TIME,
    XML_SCHEMAS_GDAY,
    XML_SCHEMAS_GMONTH,
    XML_SCHEMAS_GMONTHDAY,
    XML_SCHEMAS_GYEAR,
    XML_SCHEMAS_GYEARMONTH,
    XML_SCHEMAS_DATE,
    XML_SCHEMAS_DATETIME,
    XML_SCHEMAS_DURATION,
    XML_SCHEMAS_FLOAT,
    XML_SCHEMAS_DOUBLE,
    XML_SCHEMAS_BOOLEAN,
    XML_SCHEMAS_TOKEN,
    XML_SCHEMAS_LANGUAGE,
    XML_SCHEMAS_NMTOKEN,
    XML_SCHEMAS_NMTOKENS, 
    XML_SCHEMAS_NAME,
    XML_SCHEMAS_QNAME,
    XML_SCHEMAS_NCNAME,
    XML_SCHEMAS_ID,
    XML_SCHEMAS_IDREF,
    XML_SCHEMAS_IDREFS, 
    XML_SCHEMAS_ENTITY,
    XML_SCHEMAS_ENTITIES, 
    XML_SCHEMAS_NOTATION,
    XML_SCHEMAS_ANYURI,
    XML_SCHEMAS_INTEGER,
    XML_SCHEMAS_NPINTEGER,
    XML_SCHEMAS_NINTEGER,
    XML_SCHEMAS_NNINTEGER,
    XML_SCHEMAS_PINTEGER,
    XML_SCHEMAS_INT,
    XML_SCHEMAS_UINT,
    XML_SCHEMAS_LONG,
    XML_SCHEMAS_ULONG,
    XML_SCHEMAS_SHORT,
    XML_SCHEMAS_USHORT,
    XML_SCHEMAS_BYTE,
    XML_SCHEMAS_UBYTE,
    XML_SCHEMAS_HEXBINARY,
    XML_SCHEMAS_BASE64BINARY,
    XML_SCHEMAS_ANYTYPE,
    XML_SCHEMAS_ANYSIMPLETYPE   
} xmlSchemaValType;

/*
 * XML Schemas defines multiple type of types.
 */
typedef enum {
    XML_SCHEMA_TYPE_BASIC = 1, /* A built-in datatype */
    XML_SCHEMA_TYPE_ANY,
    XML_SCHEMA_TYPE_FACET,
    XML_SCHEMA_TYPE_SIMPLE,
    XML_SCHEMA_TYPE_COMPLEX,
    XML_SCHEMA_TYPE_SEQUENCE,
    XML_SCHEMA_TYPE_CHOICE,
    XML_SCHEMA_TYPE_ALL,
    XML_SCHEMA_TYPE_SIMPLE_CONTENT,
    XML_SCHEMA_TYPE_COMPLEX_CONTENT,
    XML_SCHEMA_TYPE_UR,
    XML_SCHEMA_TYPE_RESTRICTION,
    XML_SCHEMA_TYPE_EXTENSION,
    XML_SCHEMA_TYPE_ELEMENT,
    XML_SCHEMA_TYPE_ATTRIBUTE,
    XML_SCHEMA_TYPE_ATTRIBUTEGROUP,
    XML_SCHEMA_TYPE_GROUP,
    XML_SCHEMA_TYPE_NOTATION,
    XML_SCHEMA_TYPE_LIST,
    XML_SCHEMA_TYPE_UNION,
    XML_SCHEMA_TYPE_ANY_ATTRIBUTE,
    XML_SCHEMA_FACET_MININCLUSIVE = 1000,
    XML_SCHEMA_FACET_MINEXCLUSIVE,
    XML_SCHEMA_FACET_MAXINCLUSIVE,
    XML_SCHEMA_FACET_MAXEXCLUSIVE,
    XML_SCHEMA_FACET_TOTALDIGITS,
    XML_SCHEMA_FACET_FRACTIONDIGITS,
    XML_SCHEMA_FACET_PATTERN,
    XML_SCHEMA_FACET_ENUMERATION,
    XML_SCHEMA_FACET_WHITESPACE,
    XML_SCHEMA_FACET_LENGTH,
    XML_SCHEMA_FACET_MAXLENGTH,
    XML_SCHEMA_FACET_MINLENGTH
} xmlSchemaTypeType;

typedef enum {
    XML_SCHEMA_CONTENT_UNKNOWN = 0,
    XML_SCHEMA_CONTENT_EMPTY = 1,
    XML_SCHEMA_CONTENT_ELEMENTS,
    XML_SCHEMA_CONTENT_MIXED,
    XML_SCHEMA_CONTENT_SIMPLE,
    XML_SCHEMA_CONTENT_MIXED_OR_ELEMENTS, /* obsolete, not used */
    XML_SCHEMA_CONTENT_BASIC,
    XML_SCHEMA_CONTENT_ANY
} xmlSchemaContentType;

typedef struct _xmlSchemaVal xmlSchemaVal;
typedef xmlSchemaVal *xmlSchemaValPtr;

/* Date value */
typedef struct _xmlSchemaValDate xmlSchemaValDate;
typedef xmlSchemaValDate *xmlSchemaValDatePtr;
struct _xmlSchemaValDate {
    long		year;
    unsigned int	mon	:4;	/* 1 <=  mon    <= 12   */
    unsigned int	day	:5;	/* 1 <=  day    <= 31   */
    unsigned int	hour	:5;	/* 0 <=  hour   <= 23   */
    unsigned int	min	:6;	/* 0 <=  min    <= 59	*/
    double		sec;
    unsigned int	tz_flag	:1;	/* is tzo explicitely set? */
    signed int		tzo	:11;	/* -1440 <= tzo <= 1440 */
};

/* Duration value */
typedef struct _xmlSchemaValDuration xmlSchemaValDuration;
typedef xmlSchemaValDuration *xmlSchemaValDurationPtr;
struct _xmlSchemaValDuration {
    long	        mon;		/* mon stores years also */
    long        	day;
    double		sec;            /* sec stores min and hour also */
};

typedef struct _xmlSchemaValDecimal xmlSchemaValDecimal;
typedef xmlSchemaValDecimal *xmlSchemaValDecimalPtr;
struct _xmlSchemaValDecimal {
    /* would use long long but not portable */
    unsigned long lo;
    unsigned long mi;
    unsigned long hi;
    unsigned int extra;
    unsigned int sign:1;
    unsigned int frac:7;
    unsigned int total:8;
};

typedef struct _xmlSchemaValQName xmlSchemaValQName;
typedef xmlSchemaValQName *xmlSchemaValQNamePtr;
struct _xmlSchemaValQName {
    xmlChar *name;
    xmlChar *uri;
};

typedef struct _xmlSchemaValHex xmlSchemaValHex;
typedef xmlSchemaValHex *xmlSchemaValHexPtr;
struct _xmlSchemaValHex {
    xmlChar     *str;
    unsigned int total;
};

typedef struct _xmlSchemaValBase64 xmlSchemaValBase64;
typedef xmlSchemaValBase64 *xmlSchemaValBase64Ptr;
struct _xmlSchemaValBase64 {
    xmlChar     *str;
    unsigned int total;
};

struct _xmlSchemaVal {
    xmlSchemaValType type;
    union {
	xmlSchemaValDecimal     decimal;
        xmlSchemaValDate        date;
        xmlSchemaValDuration    dur;
	xmlSchemaValQName	qname;
	xmlSchemaValHex		hex;
	xmlSchemaValBase64	base64;
	float			f;
	double			d;
	int			b;
	xmlChar                *str;
    } value;
};

typedef struct _xmlSchemaType xmlSchemaType;
typedef xmlSchemaType *xmlSchemaTypePtr;

typedef struct _xmlSchemaFacet xmlSchemaFacet;
typedef xmlSchemaFacet *xmlSchemaFacetPtr;

/**
 * Annotation
 */
typedef struct _xmlSchemaAnnot xmlSchemaAnnot;
typedef xmlSchemaAnnot *xmlSchemaAnnotPtr;
struct _xmlSchemaAnnot {
    struct _xmlSchemaAnnot *next;
    xmlNodePtr content;         /* the annotation */
};

/**
 * XML_SCHEMAS_ANYATTR_SKIP:
 *
 * Skip unknown attribute from validation
 * Obsolete, not used anymore.
 */
#define XML_SCHEMAS_ANYATTR_SKIP	1
/**
 * XML_SCHEMAS_ANYATTR_LAX:
 *
 * Ignore validation non definition on attributes
 * Obsolete, not used anymore.
 */
#define XML_SCHEMAS_ANYATTR_LAX		2
/**
 * XML_SCHEMAS_ANYATTR_STRICT:
 *
 * Apply strict validation rules on attributes
 * Obsolete, not used anymore.
 */
#define XML_SCHEMAS_ANYATTR_STRICT	3
/**
 * XML_SCHEMAS_ANY_SKIP:
 *
 * Skip unknown attribute from validation 
 */
#define XML_SCHEMAS_ANY_SKIP        1
/**
 * XML_SCHEMAS_ANY_LAX:
 *
 * Used by wildcards.
 * Validate if type found, don't worry if not found
 */
#define XML_SCHEMAS_ANY_LAX                2
/**
 * XML_SCHEMAS_ANY_STRICT:
 *
 * Used by wildcards.
 * Apply strict validation rules
 */
#define XML_SCHEMAS_ANY_STRICT        3
/**
 * XML_SCHEMAS_ATTR_USE_PROHIBITED:
 *
 * Used by wildcards.
 * The attribute is prohibited.
 */
#define XML_SCHEMAS_ATTR_USE_PROHIBITED 0
/**
 * XML_SCHEMAS_ATTR_USE_REQUIRED:
 *
 * The attribute is required.
 */
#define XML_SCHEMAS_ATTR_USE_REQUIRED 1
/**
 * XML_SCHEMAS_ATTR_USE_OPTIONAL:
 *
 * The attribute is optional.
 */
#define XML_SCHEMAS_ATTR_USE_OPTIONAL 2
/**
 * XML_SCHEMAS_ATTR_GLOABAL:
 *
 * allow elements in no namespace
 */
#define XML_SCHEMAS_ATTR_GLOBAL        1 << 0

/**
 * XML_SCHEMAS_ATTR_NSDEFAULT:
 *
 * allow elements in no namespace
 */
#define XML_SCHEMAS_ATTR_NSDEFAULT	1 << 7

/**
 * xmlSchemaAttribute:
 * An attribute definition.
 */

typedef struct _xmlSchemaAttribute xmlSchemaAttribute;
typedef xmlSchemaAttribute *xmlSchemaAttributePtr;
struct _xmlSchemaAttribute {
    xmlSchemaTypeType type;	/* The kind of type */
    struct _xmlSchemaAttribute *next;/* the next attribute if in a group ... */
    const xmlChar *name;
    const xmlChar *id;
    const xmlChar *ref;
    const xmlChar *refNs;
    const xmlChar *typeName;
    const xmlChar *typeNs;
    xmlSchemaAnnotPtr annot;

    xmlSchemaTypePtr base;
    int occurs;
    const xmlChar *defValue;
    xmlSchemaTypePtr subtypes;
    xmlNodePtr node;
    const xmlChar *targetNamespace;
    int flags;
};

/**
 * xmlSchemaAttributeLink:
 * Used to build a list of attribute uses on complexType definitions.
 */
typedef struct _xmlSchemaAttributeLink xmlSchemaAttributeLink;
typedef xmlSchemaAttributeLink *xmlSchemaAttributeLinkPtr;
struct _xmlSchemaAttributeLink {
    struct _xmlSchemaAttributeLink *next;/* the next attribute link ... */
    struct _xmlSchemaAttribute *attr;/* the linked attribute */
};

/**
 * XML_SCHEMAS_WILDCARD_COMPLETE:
 *
 * If the wildcard is complete.
 */
#define XML_SCHEMAS_WILDCARD_COMPLETE 1 << 0

/**
 * xmlSchemaCharValueLink:
 * Used to build a list of namespaces on wildcards.
 */
typedef struct _xmlSchemaWildcardNs xmlSchemaWildcardNs;
typedef xmlSchemaWildcardNs *xmlSchemaWildcardNsPtr;
struct _xmlSchemaWildcardNs {
    struct _xmlSchemaWildcardNs *next;/* the next constraint link ... */
    const xmlChar *value;/* the value */
};

/**
 * xmlSchemaWildcard.
 * A wildcard.
 */
typedef struct _xmlSchemaWildcard xmlSchemaWildcard;
typedef xmlSchemaWildcard *xmlSchemaWildcardPtr;
struct _xmlSchemaWildcard {
    xmlSchemaTypeType type;        /* The kind of type */
    const xmlChar *id;
    xmlSchemaAnnotPtr annot;
    xmlNodePtr node;
    int minOccurs;
    int maxOccurs;
    int processContents;
    int any; /* Indicates if the ns constraint is of ##any */
    xmlSchemaWildcardNsPtr nsSet; /* The list of allowed namespaces */
    xmlSchemaWildcardNsPtr negNsSet; /* The negated namespace */
    int flags;
};

/**
 * XML_SCHEMAS_ATTRGROUP_WILDCARD_BUILDED:
 *
 * The attribute wildcard has been already builded.
 */
#define XML_SCHEMAS_ATTRGROUP_WILDCARD_BUILDED 1 << 0
/**
 * XML_SCHEMAS_ATTRGROUP_GLOBAL:
 *
 * The attribute wildcard has been already builded.
 */
#define XML_SCHEMAS_ATTRGROUP_GLOBAL 1 << 1

/**
 * An attribute group definition.
 *
 * xmlSchemaAttribute and xmlSchemaAttributeGroup start of structures
 * must be kept similar
 */
typedef struct _xmlSchemaAttributeGroup xmlSchemaAttributeGroup;
typedef xmlSchemaAttributeGroup *xmlSchemaAttributeGroupPtr;
struct _xmlSchemaAttributeGroup {
    xmlSchemaTypeType type;	/* The kind of type */
    struct _xmlSchemaAttribute *next;/* the next attribute if in a group ... */
    const xmlChar *name;
    const xmlChar *id;
    const xmlChar *ref;
    const xmlChar *refNs;
    xmlSchemaAnnotPtr annot;

    xmlSchemaAttributePtr attributes;
    xmlNodePtr node;
    int flags;
    xmlSchemaWildcardPtr attributeWildcard;
};

/**
 * xmlSchemaTypeLink:
 * Used to build a list of types (e.g. member types of
 * simpleType with variety "union").
 */
typedef struct _xmlSchemaTypeLink xmlSchemaTypeLink;
typedef xmlSchemaTypeLink *xmlSchemaTypeLinkPtr;
struct _xmlSchemaTypeLink {
    struct _xmlSchemaTypeLink *next;/* the next type link ... */
    xmlSchemaTypePtr type;/* the linked type*/
};

/**
 * xmlSchemaFacetLink:
 * Used to build a list of facets.
 */
typedef struct _xmlSchemaFacetLink xmlSchemaFacetLink;
typedef xmlSchemaFacetLink *xmlSchemaFacetLinkPtr;
struct _xmlSchemaFacetLink {
    struct _xmlSchemaFacetLink *next;/* the next facet link ... */
    xmlSchemaFacetPtr facet;/* the linked facet */
};

/**
 * XML_SCHEMAS_TYPE_MIXED:
 *
 * the element content type is mixed
 */
#define XML_SCHEMAS_TYPE_MIXED		1 << 0
/**
 * XML_SCHEMAS_TYPE_DERIVATION_METHOD_EXTENSION:
 *
 * the simple or complex type has a derivation method of "extension".
 */
#define XML_SCHEMAS_TYPE_DERIVATION_METHOD_EXTENSION                1 << 1
/**
 * XML_SCHEMAS_TYPE_DERIVATION_METHOD_RESTRICTION:
 *
 * the simple or complex type has a derivation method of "restriction".
 */
#define XML_SCHEMAS_TYPE_DERIVATION_METHOD_RESTRICTION                1 << 2
/**
 * XML_SCHEMAS_TYPE_GLOBAL:
 *
 * the type is global
 */
#define XML_SCHEMAS_TYPE_GLOBAL                1 << 3
/**
 * XML_SCHEMAS_TYPE_OWNED_ATTR_WILDCARD:
 *
 * the complexType owns an attribute wildcard, i.e.
 * it can be freed by the complexType
 */
#define XML_SCHEMAS_TYPE_OWNED_ATTR_WILDCARD    1 << 4
/**
 * XML_SCHEMAS_TYPE_VARIETY_ABSENT:
 *
 * the simpleType has a variety of "absent".
 */
#define XML_SCHEMAS_TYPE_VARIETY_ABSENT    1 << 5
/**
 * XML_SCHEMAS_TYPE_VARIETY_LIST:
 *
 * the simpleType has a variety of "list".
 */
#define XML_SCHEMAS_TYPE_VARIETY_LIST    1 << 6
/**
 * XML_SCHEMAS_TYPE_VARIETY_UNION:
 *
 * the simpleType has a variety of "union".
 */
#define XML_SCHEMAS_TYPE_VARIETY_UNION    1 << 7
/**
 * XML_SCHEMAS_TYPE_VARIETY_ATOMIC:
 *
 * the simpleType has a variety of "union".
 */
#define XML_SCHEMAS_TYPE_VARIETY_ATOMIC    1 << 8
/**
 * XML_SCHEMAS_TYPE_FINAL_EXTENSION:
 *
 * the complexType has a final of "extension".
 */
#define XML_SCHEMAS_TYPE_FINAL_EXTENSION    1 << 9
/**
 * XML_SCHEMAS_TYPE_FINAL_RESTRICTION:
 *
 * the simpleType/complexType has a final of "restriction".
 */
#define XML_SCHEMAS_TYPE_FINAL_RESTRICTION    1 << 10
/**
 * XML_SCHEMAS_TYPE_FINAL_LIST:
 *
 * the simpleType has a final of "list".
 */
#define XML_SCHEMAS_TYPE_FINAL_LIST    1 << 11
/**
 * XML_SCHEMAS_TYPE_FINAL_UNION:
 *
 * the simpleType has a final of "union".
 */
#define XML_SCHEMAS_TYPE_FINAL_UNION    1 << 12
/**
 * XML_SCHEMAS_TYPE_FINAL_UNION:
 *
 * the simpleType has a final of "union".
 */
#define XML_SCHEMAS_TYPE_FINAL_DEFAULT    1 << 13
/**
 * XML_SCHEMAS_TYPE_FINAL_UNION:
 *
 * the simpleType has a final of "union".
 */
#define XML_SCHEMAS_TYPE_BUILTIN_PRIMITIVE    1 << 14

/**
 * _xmlSchemaType:
 *
 * Schemas type definition.
 */
struct _xmlSchemaType {
    xmlSchemaTypeType type;	/* The kind of type */
    struct _xmlSchemaType *next;/* the next type if in a sequence ... */
    const xmlChar *name;
    const xmlChar *id;
    const xmlChar *ref;
    const xmlChar *refNs;
    xmlSchemaAnnotPtr annot;
    xmlSchemaTypePtr subtypes;
    xmlSchemaAttributePtr attributes;
    xmlNodePtr node;
    int minOccurs;
    int maxOccurs;

    int flags;
    const xmlChar * targetNamespace;
    xmlSchemaContentType contentType;
    const xmlChar *base;
    const xmlChar *baseNs;
    xmlSchemaTypePtr baseType;
    xmlSchemaFacetPtr facets;
    struct _xmlSchemaType *redef;/* possible redefinitions for the type */
    int recurse;
    xmlSchemaAttributeLinkPtr attributeUses;
    xmlSchemaWildcardPtr attributeWildcard;
    int builtInType;
    xmlSchemaTypeLinkPtr memberTypes;
    xmlSchemaFacetLinkPtr facetSet;
};

/*
 * xmlSchemaElement:
 * An element definition.
 *
 * xmlSchemaType, xmlSchemaFacet and xmlSchemaElement start of
 * structures must be kept similar
 */
/**
 * XML_SCHEMAS_ELEM_NILLABLE:
 *
 * the element is nillable
 */
#define XML_SCHEMAS_ELEM_NILLABLE	1 << 0
/**
 * XML_SCHEMAS_ELEM_GLOBAL:
 *
 * the element is global
 */
#define XML_SCHEMAS_ELEM_GLOBAL		1 << 1
/**
 * XML_SCHEMAS_ELEM_DEFAULT:
 *
 * the element has a default value
 */
#define XML_SCHEMAS_ELEM_DEFAULT	1 << 2
/**
 * XML_SCHEMAS_ELEM_FIXED:
 *
 * the element has a fixed value
 */
#define XML_SCHEMAS_ELEM_FIXED		1 << 3
/**
 * XML_SCHEMAS_ELEM_ABSTRACT:
 *
 * the element is abstract
 */
#define XML_SCHEMAS_ELEM_ABSTRACT	1 << 4
/**
 * XML_SCHEMAS_ELEM_TOPLEVEL:
 *
 * the element is top level
 * obsolete: use XML_SCHEMAS_ELEM_GLOBAL instead
 */
#define XML_SCHEMAS_ELEM_TOPLEVEL	1 << 5
/**
 * XML_SCHEMAS_ELEM_REF:
 *
 * the element is a reference to a type
 */
#define XML_SCHEMAS_ELEM_REF		1 << 6
/**
 * XML_SCHEMAS_ELEM_NSDEFAULT:
 *
 * allow elements in no namespace
 * Obsolete, not used anymore.
 */
#define XML_SCHEMAS_ELEM_NSDEFAULT	1 << 7

typedef struct _xmlSchemaElement xmlSchemaElement;
typedef xmlSchemaElement *xmlSchemaElementPtr;
struct _xmlSchemaElement {
    xmlSchemaTypeType type;	/* The kind of type */
    struct _xmlSchemaType *next;/* the next type if in a sequence ... */
    const xmlChar *name;
    const xmlChar *id;
    const xmlChar *ref;
    const xmlChar *refNs;
    xmlSchemaAnnotPtr annot;
    xmlSchemaTypePtr subtypes;
    xmlSchemaAttributePtr attributes;
    xmlNodePtr node;
    int minOccurs;
    int maxOccurs;

    int flags;
    const xmlChar *targetNamespace;
    const xmlChar *namedType;
    const xmlChar *namedTypeNs;
    const xmlChar *substGroup;
    const xmlChar *substGroupNs;
    const xmlChar *scope;
    const xmlChar *value;
    struct _xmlSchemaElement *refDecl;
    xmlRegexpPtr contModel;
    xmlSchemaContentType contentType;
};

/*
 * XML_SCHEMAS_FACET_UNKNOWN:
 *
 * unknown facet handling
 */
#define XML_SCHEMAS_FACET_UNKNOWN	0
/*
 * XML_SCHEMAS_FACET_PRESERVE:
 *
 * preserve the type of the facet
 */
#define XML_SCHEMAS_FACET_PRESERVE	1
/*
 * XML_SCHEMAS_FACET_REPLACE:
 *
 * replace the type of the facet
 */
#define XML_SCHEMAS_FACET_REPLACE	2
/*
 * XML_SCHEMAS_FACET_COLLAPSE:
 *
 * collapse the types of the facet
 */
#define XML_SCHEMAS_FACET_COLLAPSE	3
/**
 * A facet definition.
 */
struct _xmlSchemaFacet {
    xmlSchemaTypeType type;	/* The kind of type */
    struct _xmlSchemaFacet *next;/* the next type if in a sequence ... */
    const xmlChar *value;
    const xmlChar *id;
    xmlSchemaAnnotPtr annot;
    xmlNodePtr node;
    int fixed;
    int whitespace;
    xmlSchemaValPtr val;
    xmlRegexpPtr    regexp;
};

/**
 * A notation definition.
 */
typedef struct _xmlSchemaNotation xmlSchemaNotation;
typedef xmlSchemaNotation *xmlSchemaNotationPtr;
struct _xmlSchemaNotation {
    xmlSchemaTypeType type;	/* The kind of type */
    const xmlChar *name;
    xmlSchemaAnnotPtr annot;
    const xmlChar *identifier;
};

/**
 * XML_SCHEMAS_QUALIF_ELEM:
 *
 * the shemas requires qualified elements
 */
#define XML_SCHEMAS_QUALIF_ELEM		1 << 0
/**
 * XML_SCHEMAS_QUALIF_ATTR:
 *
 * the shemas requires qualified attributes
 */
#define XML_SCHEMAS_QUALIF_ATTR	    1 << 1
/**
 * XML_SCHEMAS_FINAL_DEFAULT_EXTENSION:
 *
 * the shema has "extension" in the set of finalDefault.
 */
#define XML_SCHEMAS_FINAL_DEFAULT_EXTENSION	1 << 2
/**
 * XML_SCHEMAS_FINAL_DEFAULT_RESTRICTION:
 *
 * the shema has "restriction" in the set of finalDefault.
 */
#define XML_SCHEMAS_FINAL_DEFAULT_RESTRICTION	    1 << 3
/**
 * XML_SCHEMAS_FINAL_DEFAULT_LIST:
 *
 * the shema has "list" in the set of finalDefault.
 */
#define XML_SCHEMAS_FINAL_DEFAULT_LIST	    1 << 4
/**
 * XML_SCHEMAS_FINAL_DEFAULT_UNION:
 *
 * the shema has "union" in the set of finalDefault.
 */
#define XML_SCHEMAS_FINAL_DEFAULT_UNION	    1 << 5
/**
 * _xmlSchema:
 *
 * A Schemas definition
 */
struct _xmlSchema {
    const xmlChar *name;        /* schema name */
    const xmlChar *targetNamespace;     /* the target namespace */
    const xmlChar *version;
    const xmlChar *id;
    xmlDocPtr doc;
    xmlSchemaAnnotPtr annot;
    int flags;

    xmlHashTablePtr typeDecl;
    xmlHashTablePtr attrDecl;
    xmlHashTablePtr attrgrpDecl;
    xmlHashTablePtr elemDecl;
    xmlHashTablePtr notaDecl;

    xmlHashTablePtr schemasImports;

    void *_private;	/* unused by the library for users or bindings */
    xmlHashTablePtr groupDecl;
    xmlDictPtr      dict;
    void *includes;     /* the includes, this is opaque for now */
    int preserve;	/* whether to free the document */
};

/*
 * These are the entries in the schemas importSchemas hash table
 */
typedef struct _xmlSchemaImport xmlSchemaImport;
typedef xmlSchemaImport *xmlSchemaImportPtr;
struct _xmlSchemaImport {
    const xmlChar *schemaLocation;
    struct _xmlSchema * schema;
    int preserve;
};

XMLPUBFUN void XMLCALL 	xmlSchemaFreeType	(xmlSchemaTypePtr type);
XMLPUBFUN void XMLCALL 	xmlSchemaFreeWildcard(xmlSchemaWildcardPtr wildcard);

#ifdef __cplusplus
}
#endif

#endif /* LIBXML_SCHEMAS_ENABLED */
#endif /* __XML_SCHEMA_INTERNALS_H__ */


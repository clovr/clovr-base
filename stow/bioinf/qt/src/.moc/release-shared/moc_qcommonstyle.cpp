/****************************************************************************
** QCommonStyle meta object code from reading C++ file 'qcommonstyle.h'
**
** Created: Sat Dec 12 03:13:51 2009
**      by: The Qt MOC ($Id: qt/moc_yacc.cpp   3.3.8   edited Feb 2 14:59 $)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#undef QT_NO_COMPAT
#include "../../styles/qcommonstyle.h"
#include <qmetaobject.h>
#include <qapplication.h>

#include <private/qucomextra_p.h>
#if !defined(Q_MOC_OUTPUT_REVISION) || (Q_MOC_OUTPUT_REVISION != 26)
#error "This file was generated using the moc from 3.3.8. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

const char *QCommonStyle::className() const
{
    return "QCommonStyle";
}

QMetaObject *QCommonStyle::metaObj = 0;
static QMetaObjectCleanUp cleanUp_QCommonStyle( "QCommonStyle", &QCommonStyle::staticMetaObject );

#ifndef QT_NO_TRANSLATION
QString QCommonStyle::tr( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "QCommonStyle", s, c, QApplication::DefaultCodec );
    else
	return QString::fromLatin1( s );
}
#ifndef QT_NO_TRANSLATION_UTF8
QString QCommonStyle::trUtf8( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "QCommonStyle", s, c, QApplication::UnicodeUTF8 );
    else
	return QString::fromUtf8( s );
}
#endif // QT_NO_TRANSLATION_UTF8

#endif // QT_NO_TRANSLATION

QMetaObject* QCommonStyle::staticMetaObject()
{
    if ( metaObj )
	return metaObj;
    QMetaObject* parentObject = QStyle::staticMetaObject();
    metaObj = QMetaObject::new_metaobject(
	"QCommonStyle", parentObject,
	0, 0,
	0, 0,
#ifndef QT_NO_PROPERTIES
	0, 0,
	0, 0,
#endif // QT_NO_PROPERTIES
	0, 0 );
    cleanUp_QCommonStyle.setMetaObject( metaObj );
    return metaObj;
}

void* QCommonStyle::qt_cast( const char* clname )
{
    if ( !qstrcmp( clname, "QCommonStyle" ) )
	return this;
    return QStyle::qt_cast( clname );
}

bool QCommonStyle::qt_invoke( int _id, QUObject* _o )
{
    return QStyle::qt_invoke(_id,_o);
}

bool QCommonStyle::qt_emit( int _id, QUObject* _o )
{
    return QStyle::qt_emit(_id,_o);
}
#ifndef QT_NO_PROPERTIES

bool QCommonStyle::qt_property( int id, int f, QVariant* v)
{
    return QStyle::qt_property( id, f, v);
}

bool QCommonStyle::qt_static_property( QObject* , int , int , QVariant* ){ return FALSE; }
#endif // QT_NO_PROPERTIES

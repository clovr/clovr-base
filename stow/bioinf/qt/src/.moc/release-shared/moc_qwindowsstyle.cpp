/****************************************************************************
** QWindowsStyle meta object code from reading C++ file 'qwindowsstyle.h'
**
** Created: Sat Dec 12 03:13:53 2009
**      by: The Qt MOC ($Id: qt/moc_yacc.cpp   3.3.8   edited Feb 2 14:59 $)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#undef QT_NO_COMPAT
#include "../../styles/qwindowsstyle.h"
#include <qmetaobject.h>
#include <qapplication.h>

#include <private/qucomextra_p.h>
#if !defined(Q_MOC_OUTPUT_REVISION) || (Q_MOC_OUTPUT_REVISION != 26)
#error "This file was generated using the moc from 3.3.8. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

const char *QWindowsStyle::className() const
{
    return "QWindowsStyle";
}

QMetaObject *QWindowsStyle::metaObj = 0;
static QMetaObjectCleanUp cleanUp_QWindowsStyle( "QWindowsStyle", &QWindowsStyle::staticMetaObject );

#ifndef QT_NO_TRANSLATION
QString QWindowsStyle::tr( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "QWindowsStyle", s, c, QApplication::DefaultCodec );
    else
	return QString::fromLatin1( s );
}
#ifndef QT_NO_TRANSLATION_UTF8
QString QWindowsStyle::trUtf8( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "QWindowsStyle", s, c, QApplication::UnicodeUTF8 );
    else
	return QString::fromUtf8( s );
}
#endif // QT_NO_TRANSLATION_UTF8

#endif // QT_NO_TRANSLATION

QMetaObject* QWindowsStyle::staticMetaObject()
{
    if ( metaObj )
	return metaObj;
    QMetaObject* parentObject = QCommonStyle::staticMetaObject();
    metaObj = QMetaObject::new_metaobject(
	"QWindowsStyle", parentObject,
	0, 0,
	0, 0,
#ifndef QT_NO_PROPERTIES
	0, 0,
	0, 0,
#endif // QT_NO_PROPERTIES
	0, 0 );
    cleanUp_QWindowsStyle.setMetaObject( metaObj );
    return metaObj;
}

void* QWindowsStyle::qt_cast( const char* clname )
{
    if ( !qstrcmp( clname, "QWindowsStyle" ) )
	return this;
    return QCommonStyle::qt_cast( clname );
}

bool QWindowsStyle::qt_invoke( int _id, QUObject* _o )
{
    return QCommonStyle::qt_invoke(_id,_o);
}

bool QWindowsStyle::qt_emit( int _id, QUObject* _o )
{
    return QCommonStyle::qt_emit(_id,_o);
}
#ifndef QT_NO_PROPERTIES

bool QWindowsStyle::qt_property( int id, int f, QVariant* v)
{
    return QCommonStyle::qt_property( id, f, v);
}

bool QWindowsStyle::qt_static_property( QObject* , int , int , QVariant* ){ return FALSE; }
#endif // QT_NO_PROPERTIES

/****************************************************************************
** QSqlDriver meta object code from reading C++ file 'qsqldriver.h'
**
** Created: Sat Dec 12 03:13:48 2009
**      by: The Qt MOC ($Id: qt/moc_yacc.cpp   3.3.8   edited Feb 2 14:59 $)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#undef QT_NO_COMPAT
#include "../../sql/qsqldriver.h"
#include <qmetaobject.h>
#include <qapplication.h>

#include <private/qucomextra_p.h>
#if !defined(Q_MOC_OUTPUT_REVISION) || (Q_MOC_OUTPUT_REVISION != 26)
#error "This file was generated using the moc from 3.3.8. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

const char *QSqlDriver::className() const
{
    return "QSqlDriver";
}

QMetaObject *QSqlDriver::metaObj = 0;
static QMetaObjectCleanUp cleanUp_QSqlDriver( "QSqlDriver", &QSqlDriver::staticMetaObject );

#ifndef QT_NO_TRANSLATION
QString QSqlDriver::tr( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "QSqlDriver", s, c, QApplication::DefaultCodec );
    else
	return QString::fromLatin1( s );
}
#ifndef QT_NO_TRANSLATION_UTF8
QString QSqlDriver::trUtf8( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "QSqlDriver", s, c, QApplication::UnicodeUTF8 );
    else
	return QString::fromUtf8( s );
}
#endif // QT_NO_TRANSLATION_UTF8

#endif // QT_NO_TRANSLATION

QMetaObject* QSqlDriver::staticMetaObject()
{
    if ( metaObj )
	return metaObj;
    QMetaObject* parentObject = QObject::staticMetaObject();
    metaObj = QMetaObject::new_metaobject(
	"QSqlDriver", parentObject,
	0, 0,
	0, 0,
#ifndef QT_NO_PROPERTIES
	0, 0,
	0, 0,
#endif // QT_NO_PROPERTIES
	0, 0 );
    cleanUp_QSqlDriver.setMetaObject( metaObj );
    return metaObj;
}

void* QSqlDriver::qt_cast( const char* clname )
{
    if ( !qstrcmp( clname, "QSqlDriver" ) )
	return this;
    return QObject::qt_cast( clname );
}

bool QSqlDriver::qt_invoke( int _id, QUObject* _o )
{
    return QObject::qt_invoke(_id,_o);
}

bool QSqlDriver::qt_emit( int _id, QUObject* _o )
{
    return QObject::qt_emit(_id,_o);
}
#ifndef QT_NO_PROPERTIES

bool QSqlDriver::qt_property( int id, int f, QVariant* v)
{
    return QObject::qt_property( id, f, v);
}

bool QSqlDriver::qt_static_property( QObject* , int , int , QVariant* ){ return FALSE; }
#endif // QT_NO_PROPERTIES

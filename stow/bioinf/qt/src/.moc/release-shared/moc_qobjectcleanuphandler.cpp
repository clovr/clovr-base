/****************************************************************************
** QObjectCleanupHandler meta object code from reading C++ file 'qobjectcleanuphandler.h'
**
** Created: Sat Dec 12 03:13:06 2009
**      by: The Qt MOC ($Id: qt/moc_yacc.cpp   3.3.8   edited Feb 2 14:59 $)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#undef QT_NO_COMPAT
#include "../../kernel/qobjectcleanuphandler.h"
#include <qmetaobject.h>
#include <qapplication.h>

#include <private/qucomextra_p.h>
#if !defined(Q_MOC_OUTPUT_REVISION) || (Q_MOC_OUTPUT_REVISION != 26)
#error "This file was generated using the moc from 3.3.8. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

const char *QObjectCleanupHandler::className() const
{
    return "QObjectCleanupHandler";
}

QMetaObject *QObjectCleanupHandler::metaObj = 0;
static QMetaObjectCleanUp cleanUp_QObjectCleanupHandler( "QObjectCleanupHandler", &QObjectCleanupHandler::staticMetaObject );

#ifndef QT_NO_TRANSLATION
QString QObjectCleanupHandler::tr( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "QObjectCleanupHandler", s, c, QApplication::DefaultCodec );
    else
	return QString::fromLatin1( s );
}
#ifndef QT_NO_TRANSLATION_UTF8
QString QObjectCleanupHandler::trUtf8( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "QObjectCleanupHandler", s, c, QApplication::UnicodeUTF8 );
    else
	return QString::fromUtf8( s );
}
#endif // QT_NO_TRANSLATION_UTF8

#endif // QT_NO_TRANSLATION

QMetaObject* QObjectCleanupHandler::staticMetaObject()
{
    if ( metaObj )
	return metaObj;
    QMetaObject* parentObject = QObject::staticMetaObject();
    static const QUParameter param_slot_0[] = {
	{ 0, &static_QUType_ptr, "QObject", QUParameter::In }
    };
    static const QUMethod slot_0 = {"objectDestroyed", 1, param_slot_0 };
    static const QMetaData slot_tbl[] = {
	{ "objectDestroyed(QObject*)", &slot_0, QMetaData::Private }
    };
    metaObj = QMetaObject::new_metaobject(
	"QObjectCleanupHandler", parentObject,
	slot_tbl, 1,
	0, 0,
#ifndef QT_NO_PROPERTIES
	0, 0,
	0, 0,
#endif // QT_NO_PROPERTIES
	0, 0 );
    cleanUp_QObjectCleanupHandler.setMetaObject( metaObj );
    return metaObj;
}

void* QObjectCleanupHandler::qt_cast( const char* clname )
{
    if ( !qstrcmp( clname, "QObjectCleanupHandler" ) )
	return this;
    return QObject::qt_cast( clname );
}

bool QObjectCleanupHandler::qt_invoke( int _id, QUObject* _o )
{
    switch ( _id - staticMetaObject()->slotOffset() ) {
    case 0: objectDestroyed((QObject*)static_QUType_ptr.get(_o+1)); break;
    default:
	return QObject::qt_invoke( _id, _o );
    }
    return TRUE;
}

bool QObjectCleanupHandler::qt_emit( int _id, QUObject* _o )
{
    return QObject::qt_emit(_id,_o);
}
#ifndef QT_NO_PROPERTIES

bool QObjectCleanupHandler::qt_property( int id, int f, QVariant* v)
{
    return QObject::qt_property( id, f, v);
}

bool QObjectCleanupHandler::qt_static_property( QObject* , int , int , QVariant* ){ return FALSE; }
#endif // QT_NO_PROPERTIES

/****************************************************************************
** QGrid meta object code from reading C++ file 'qgrid.h'
**
** Created: Sat Dec 12 03:13:17 2009
**      by: The Qt MOC ($Id: qt/moc_yacc.cpp   3.3.8   edited Feb 2 14:59 $)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#undef QT_NO_COMPAT
#include "../../widgets/qgrid.h"
#include <qmetaobject.h>
#include <qapplication.h>

#include <private/qucomextra_p.h>
#if !defined(Q_MOC_OUTPUT_REVISION) || (Q_MOC_OUTPUT_REVISION != 26)
#error "This file was generated using the moc from 3.3.8. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

const char *QGrid::className() const
{
    return "QGrid";
}

QMetaObject *QGrid::metaObj = 0;
static QMetaObjectCleanUp cleanUp_QGrid( "QGrid", &QGrid::staticMetaObject );

#ifndef QT_NO_TRANSLATION
QString QGrid::tr( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "QGrid", s, c, QApplication::DefaultCodec );
    else
	return QString::fromLatin1( s );
}
#ifndef QT_NO_TRANSLATION_UTF8
QString QGrid::trUtf8( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "QGrid", s, c, QApplication::UnicodeUTF8 );
    else
	return QString::fromUtf8( s );
}
#endif // QT_NO_TRANSLATION_UTF8

#endif // QT_NO_TRANSLATION

QMetaObject* QGrid::staticMetaObject()
{
    if ( metaObj )
	return metaObj;
    QMetaObject* parentObject = QFrame::staticMetaObject();
    metaObj = QMetaObject::new_metaobject(
	"QGrid", parentObject,
	0, 0,
	0, 0,
#ifndef QT_NO_PROPERTIES
	0, 0,
	0, 0,
#endif // QT_NO_PROPERTIES
	0, 0 );
    cleanUp_QGrid.setMetaObject( metaObj );
    return metaObj;
}

void* QGrid::qt_cast( const char* clname )
{
    if ( !qstrcmp( clname, "QGrid" ) )
	return this;
    return QFrame::qt_cast( clname );
}

bool QGrid::qt_invoke( int _id, QUObject* _o )
{
    return QFrame::qt_invoke(_id,_o);
}

bool QGrid::qt_emit( int _id, QUObject* _o )
{
    return QFrame::qt_emit(_id,_o);
}
#ifndef QT_NO_PROPERTIES

bool QGrid::qt_property( int id, int f, QVariant* v)
{
    return QFrame::qt_property( id, f, v);
}

bool QGrid::qt_static_property( QObject* , int , int , QVariant* ){ return FALSE; }
#endif // QT_NO_PROPERTIES

/****************************************************************************
** QCDEStyle meta object code from reading C++ file 'qcdestyle.h'
**
** Created: Sat Dec 12 03:13:52 2009
**      by: The Qt MOC ($Id: qt/moc_yacc.cpp   3.3.8   edited Feb 2 14:59 $)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#undef QT_NO_COMPAT
#include "../../styles/qcdestyle.h"
#include <qmetaobject.h>
#include <qapplication.h>

#include <private/qucomextra_p.h>
#if !defined(Q_MOC_OUTPUT_REVISION) || (Q_MOC_OUTPUT_REVISION != 26)
#error "This file was generated using the moc from 3.3.8. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

const char *QCDEStyle::className() const
{
    return "QCDEStyle";
}

QMetaObject *QCDEStyle::metaObj = 0;
static QMetaObjectCleanUp cleanUp_QCDEStyle( "QCDEStyle", &QCDEStyle::staticMetaObject );

#ifndef QT_NO_TRANSLATION
QString QCDEStyle::tr( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "QCDEStyle", s, c, QApplication::DefaultCodec );
    else
	return QString::fromLatin1( s );
}
#ifndef QT_NO_TRANSLATION_UTF8
QString QCDEStyle::trUtf8( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "QCDEStyle", s, c, QApplication::UnicodeUTF8 );
    else
	return QString::fromUtf8( s );
}
#endif // QT_NO_TRANSLATION_UTF8

#endif // QT_NO_TRANSLATION

QMetaObject* QCDEStyle::staticMetaObject()
{
    if ( metaObj )
	return metaObj;
    QMetaObject* parentObject = QMotifStyle::staticMetaObject();
    metaObj = QMetaObject::new_metaobject(
	"QCDEStyle", parentObject,
	0, 0,
	0, 0,
#ifndef QT_NO_PROPERTIES
	0, 0,
	0, 0,
#endif // QT_NO_PROPERTIES
	0, 0 );
    cleanUp_QCDEStyle.setMetaObject( metaObj );
    return metaObj;
}

void* QCDEStyle::qt_cast( const char* clname )
{
    if ( !qstrcmp( clname, "QCDEStyle" ) )
	return this;
    return QMotifStyle::qt_cast( clname );
}

bool QCDEStyle::qt_invoke( int _id, QUObject* _o )
{
    return QMotifStyle::qt_invoke(_id,_o);
}

bool QCDEStyle::qt_emit( int _id, QUObject* _o )
{
    return QMotifStyle::qt_emit(_id,_o);
}
#ifndef QT_NO_PROPERTIES

bool QCDEStyle::qt_property( int id, int f, QVariant* v)
{
    return QMotifStyle::qt_property( id, f, v);
}

bool QCDEStyle::qt_static_property( QObject* , int , int , QVariant* ){ return FALSE; }
#endif // QT_NO_PROPERTIES

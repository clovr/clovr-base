/****************************************************************************
** SourceEditor meta object code from reading C++ file 'sourceeditor.h'
**
** Created: Sat Dec 12 03:14:16 2009
**      by: The Qt MOC ($Id: qt/moc_yacc.cpp   3.3.8   edited Feb 2 14:59 $)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#undef QT_NO_COMPAT
#include "../../sourceeditor.h"
#include <qmetaobject.h>
#include <qapplication.h>

#include <private/qucomextra_p.h>
#if !defined(Q_MOC_OUTPUT_REVISION) || (Q_MOC_OUTPUT_REVISION != 26)
#error "This file was generated using the moc from 3.3.8. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

const char *SourceEditor::className() const
{
    return "SourceEditor";
}

QMetaObject *SourceEditor::metaObj = 0;
static QMetaObjectCleanUp cleanUp_SourceEditor( "SourceEditor", &SourceEditor::staticMetaObject );

#ifndef QT_NO_TRANSLATION
QString SourceEditor::tr( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "SourceEditor", s, c, QApplication::DefaultCodec );
    else
	return QString::fromLatin1( s );
}
#ifndef QT_NO_TRANSLATION_UTF8
QString SourceEditor::trUtf8( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "SourceEditor", s, c, QApplication::UnicodeUTF8 );
    else
	return QString::fromUtf8( s );
}
#endif // QT_NO_TRANSLATION_UTF8

#endif // QT_NO_TRANSLATION

QMetaObject* SourceEditor::staticMetaObject()
{
    if ( metaObj )
	return metaObj;
    QMetaObject* parentObject = QVBox::staticMetaObject();
    metaObj = QMetaObject::new_metaobject(
	"SourceEditor", parentObject,
	0, 0,
	0, 0,
#ifndef QT_NO_PROPERTIES
	0, 0,
	0, 0,
#endif // QT_NO_PROPERTIES
	0, 0 );
    cleanUp_SourceEditor.setMetaObject( metaObj );
    return metaObj;
}

void* SourceEditor::qt_cast( const char* clname )
{
    if ( !qstrcmp( clname, "SourceEditor" ) )
	return this;
    return QVBox::qt_cast( clname );
}

bool SourceEditor::qt_invoke( int _id, QUObject* _o )
{
    return QVBox::qt_invoke(_id,_o);
}

bool SourceEditor::qt_emit( int _id, QUObject* _o )
{
    return QVBox::qt_emit(_id,_o);
}
#ifndef QT_NO_PROPERTIES

bool SourceEditor::qt_property( int id, int f, QVariant* v)
{
    return QVBox::qt_property( id, f, v);
}

bool SourceEditor::qt_static_property( QObject* , int , int , QVariant* ){ return FALSE; }
#endif // QT_NO_PROPERTIES

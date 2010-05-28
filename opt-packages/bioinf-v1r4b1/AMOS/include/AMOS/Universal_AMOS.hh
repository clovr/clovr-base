////////////////////////////////////////////////////////////////////////////////
//! \file
//! \author Adam M Phillippy
//! \date 06/18/2003
//!
//! \brief Header for Universal_t
//!
////////////////////////////////////////////////////////////////////////////////

#ifndef __Universal_AMOS_HH
#define __Universal_AMOS_HH 1

#include "Message_AMOS.hh"
#include "datatypes_AMOS.hh"
#include "databanks_AMOS.hh"
#include <string>
#include <sstream>
#include <utility>




namespace AMOS {

//================================================ Universal_t =================
//! \brief A universal base class that can be used by Banks or Messages
//!
//! All AMOS objects that can be read as Messages and stored in a Bank should
//! be derived from this class. In addition, the single comment field in this
//! class can be used for storage of any data that a type does not yet exist
//! for, perhaps in XML format or similar.
//!
//==============================================================================
class Universal_t : public IBankable_t, public IMessagable_t
{

private:

  Status_t status_m;          //!< status char
  std::string comment_m;      //!< comment string


protected:

  //--------------------------------------------------- readRecord -------------
  virtual void readRecord (std::istream & fix, std::istream & var)
  {
    fix . get (status_m);
    std::getline (var, comment_m, '\0');
  }

  //--------------------------------------------------- readRecordFix ----------
  virtual void readRecordFix (std::istream & fix)
  {
    fix . get (status_m);
    comment_m.clear();
  }

  //--------------------------------------------------- writeRecord ------------
  virtual void writeRecord (std::ostream & fix, std::ostream & var) const
  {
    fix . put (status_m);
    var . write (comment_m . c_str( ), comment_m . size( ) + 1);
  }


public:

  static const NCode_t NCODE;
  //!< The NCode type identifier for this object


  //--------------------------------------------------- Universal_t ------------
  //! \brief Constructs an empty Universal_t object
  //!
  //! Set IID to NULL_ID, comment to empty string and all flags to false.
  //!
  Universal_t ( )
  {
    status_m = NULL_STATUS;
  }


  //--------------------------------------------------- Universal_t ------------
  //! \brief Copy constructor
  //!
  Universal_t (const Universal_t & source)
  {
    *this = source;
  }


  //--------------------------------------------------- ~Universal_t -----------
  //! \brief Virtual destructor
  //!
  virtual ~Universal_t ( )
  {

  }


  //--------------------------------------------------- clear ------------------
  virtual void clear ( )
  {
    IBankable_t::clear( );
    status_m = NULL_STATUS;
    comment_m . erase( );
  }


  //--------------------------------------------------- getComment -------------
  //! \brief Get the comment string
  //!
  //! \return The comment string
  //!
  const std::string & getComment ( ) const
  {
    return comment_m;
  }


  //--------------------------------------------------- getStatus --------------
  //! \brief Get the status value
  //!
  //! \return The status value
  //!
  const Status_t getStatus ( ) const
  {
    return status_m;
  }


  //--------------------------------------------------- getNCode ---------------
  virtual NCode_t getNCode ( ) const
  {
    return Universal_t::NCODE;
  }


  //--------------------------------------------------- readMessage ------------
  virtual void readMessage (const Message_t & msg);


  //--------------------------------------------------- setComment -------------
  //! \brief Set the comment string
  //!
  //! \param comment The new comment string
  //! \return void
  //!
  void setComment (const std::string & comment)
  {
    comment_m = comment;
  }


  //--------------------------------------------------- setStatus --------------
  //! \brief Set the status value
  //!
  //! \param status The new status value
  //! \return void
  //!
  void setStatus (Status_t status)
  {
    status_m = status;
  }


  //--------------------------------------------------- writeMessage -----------
  virtual void writeMessage (Message_t & msg) const;

};

} // namespace AMOS

#endif // #ifndef __Universal_AMOS_HH

--***
/**	functie pt. a insera un XML intr-un	alt XML  (nu merge modify XML pe SQL 2005) */
Create
function fInsereazaXmlInXml (@x1 XML, @x2 XML)
returns XML
as
Begin
-- nu se poate insera intr-un xml null
      if (@x1 is null)
            return null

	  if ((@x1.value('count(/*)','int') = 0) OR (@x2 is null))
            return @x1

      if (@x2.value('count(/*)','int') = 0)
            return @x1

      if ((@x1.value('count(/*)','int') > 1) OR (@x2.value('count(/*)','int') > 1))
            return @x1 

      declare @x XML
      set @x = CONVERT(XML, (CONVERT(nvarchar(MAX), @x1) + CONVERT(nvarchar(MAX), @x2)))
      set @x.modify('insert /*[2] as last into /*[1]')
      set @x.modify('delete /*[2]')
      return @x
End

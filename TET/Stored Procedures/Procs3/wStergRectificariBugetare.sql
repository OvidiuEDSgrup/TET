create procedure  [dbo].[wStergRectificariBugetare] @sesiune varchar(50), @parXML xml
as

	DECLARE @indbug varchar(20), @tip varchar(2),@numar varchar(13),@data datetime,@cont_debitor varchar(13),
	@cont_creditor varchar(13),@suma float,@valuta varchar(3),
	@curs float,@suma_valuta float,@explicatii varchar(50),
	@nr_pozitie int,@loc_munca varchar(9),@comanda varchar(40),@tert varchar(13),@jurnal varchar(3),
	@data_operarii datetime,@ora_operarii varchar(6),@trimestru varchar(5),@o_data datetime
        
   
        Set @indbug = @parXML.value('(/row/@indbug)[1]','varchar(20)')
        Set @trimestru = isnull(@parXML.value('(/row/row/@trimestru)[1]','varchar(5)'),0)
        Set @suma = isnull(@parXML.value('(/row/row/@suma)[1]','float'),0)
        Set @nr_pozitie = isnull(@parXML.value('(/row/row/@nr_pozitie)[1]','float'),0)
        Set @valuta = isnull(@parXML.value('(/row/row/@valuta)[1]','varchar(3)'),'')
        Set @curs = isnull(@parXML.value('(/row/row/@curs)[1]','float'),0)
        Set @o_data = @parXML.value('(/row/row/@o_data)[1]','datetime')
        Set @explicatii = isnull(@parXML.value('(/row/row/@explicatii)[1]','varchar(50)'),'')

/*declare @mesajeroare varchar(500)
    set @trimestru=(case when @trimestru='I'  then '1'
                         when @trimestru='II' then '2'
                         when @trimestru='III'then '3'
                         when @trimestru='IV' then '4' end)   
    
    set @mesajeroare=     
    (case when exists (select 1 from angbug a where a.indicator=@indbug and datepart(quarter,data)>=convert(varchar,@trimestru)) then 'O rectificare bugetare la un buget alocat, pe baza caruia s-au facut angajamente bugetare, nu poate fi stearsa!'
     else '' end)

if @mesajeroare<>''
  raiserror(@mesajeroare, 11, 1)if @mesajeroare=''*/
	delete from pozncon
	 where  substring(comanda,21,20) = @indbug and subunitate='1' and tip='AO' and nr_pozitie=@nr_pozitie

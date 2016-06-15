--***
create procedure wOPCorectieCosturi @sesiune varchar(50), @parXML xml        
as      
      
declare @subunitate char(9), @data datetime , @cdeb char(20), @ccre char(20), @suma float,
@lmV char(9), @comandaV char(20), @articolV char(20),   
@lmN char(9), @comandaN char(20), @articolN char(20),
@numar char(20), @Utilizator char(10), @binar varbinary(128), @err int
--
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output        
set @data=ISNULL(@parXML.value('(/parametri/@data)[1]', 'datetime'), '')      
set @cdeb=ISNULL(@parXML.value('(/parametri/@cdeb)[1]', 'char(20)'), '')      
set @ccre=ISNULL(@parXML.value('(/parametri/@ccre)[1]', 'char(20)'), '') 
set @suma=ISNULL(@parXML.value('(/parametri/@suma)[1]', 'float'), '')
set @lmV=ISNULL(@parXML.value('(/parametri/@lmV)[1]', 'char(9)'), '')      
set @comandaV=ISNULL(@parXML.value('(/parametri/@comandaV)[1]', 'char(20)'), '')      
set @articolV=ISNULL(@parXML.value('(/parametri/@articolV)[1]', 'char(20)'), '')      
set @lmN=ISNULL(@parXML.value('(/parametri/@lmN)[1]', 'char(9)'), '')      
set @comandaN=ISNULL(@parXML.value('(/parametri/@comandaN)[1]', 'char(20)'), '')      
set @articolN=ISNULL(@parXML.value('(/parametri/@articolN)[1]', 'char(20)'), '')
declare @nr int
set @nr=(select COUNT(1) from ncon where Numar like 'CORCC%' and MONTH(data)=MONTH(@data) and YEAR(data)=YEAR(@data))
set @nr=@nr+1
set @numar='CORCC'+cast(@nr as char(20))
EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
IF @Utilizator IS NULL
	RETURN -1

--Verificare luna blocata in PC
--
begin try  
	set @err = 0
	--
	if @suma=0 and @err=0
		set @err='1'
	if @cdeb='' and @err=0
		set @err='2'
	if @ccre='' and @err=0
		set @err='3'
	if exists (select * from pozncon where Data=@data and Cont_debitor=@cdeb and Cont_creditor=@ccre and Suma=-@suma and Loc_munca=@lmV and Comanda=@comandaV and tert=@articolV) and @err=0
		set @err='4'
	if (select are_analitice from conturi where cont=@cdeb)=1 and @err=0
		set @err='5'
	if (select are_analitice from conturi where cont=@ccre)=1 and @err=0
		set @err='6'
	declare @aiPC int, @liPC int
	set @liPC=ISNULL((select val_numerica from par where Tip_parametru='PC' and Parametru='LUNAINC' AND Val_logica=1),0)
	set @aiPC=ISNULL((select val_numerica from par where Tip_parametru='PC' and Parametru='ANULINC' AND Val_logica=1),0)
	if @aiPC>YEAR(@data) or (@aiPC=YEAR(@data) and @liPC>=MONTH(@data))
		set @err='7'
	--
	if @err<>0
		raiserror('Eroare', 11, 1)  
	--
	if @err=0
		begin
			set @binar=cast('modificarelunablocata' as varbinary(128))
			set CONTEXT_INFO @binar
			insert into pozncon (Subunitate,Tip,Numar,Data,Cont_debitor, Cont_creditor, Suma, Valuta, Curs, Suma_valuta, Explicatii, Utilizator, Data_operarii, Ora_operarii, 
			Nr_pozitie, Loc_munca, Comanda, Tert, Jurnal)
			values (@subunitate, 'NC', @numar, @data, @cdeb, @ccre, -@suma, '', 0, 0, 'Corectie costuri',
			@Utilizator, 
			convert(datetime, convert(char(10), getdate(), 104), 104),
			RTrim(replace(convert(char(8), getdate(), 108), ':', '')),
			'1',@lmV,@comandaV,@articolV,'')
			insert into pozncon (Subunitate,Tip,Numar,Data,Cont_debitor, Cont_creditor, Suma, Valuta, Curs, Suma_valuta, Explicatii, Utilizator, Data_operarii, Ora_operarii, 
			Nr_pozitie, Loc_munca, Comanda, Tert, Jurnal)
			values (@subunitate, 'NC', @numar, @data, @cdeb, @ccre, @suma, '', 0, 0, 'Corectie costuri',
			@Utilizator, 
			convert(datetime, convert(char(10), getdate(), 104), 104),
			RTrim(replace(convert(char(8), getdate(), 108), ':', '')),
			'2',@lmN,@comandaN,@articolN,'')
			set CONTEXT_INFO 0x00   
		end
		select 0 as coderr, 'Corectie efectuata cu succes, vezi nota contabila '+rtrim(@numar) as msgerr for xml raw  
end try  
--
begin catch  
	if @err='1'
		select 1 as coderr, 'Suma nu poate fi 0!' as msgerr for xml raw  
	else if @err='2'
		select 2 as coderr, 'Introduceti contul debitor!' as msgerr for xml raw 
	else if @err='3'
		select 3 as coderr, 'Introduceti contul creditor!' as msgerr for xml raw 
	else if @err='4'
		select 4 as coderr, 'Ati mai introdus aceasta nota contabila!' as msgerr for xml raw 
	else if @err='5'
		select 5 as coderr, 'Contul debitor are analitice!' as msgerr for xml raw 
	else if @err='6'
		select 6 as coderr, 'Contul creditor are analitice!' as msgerr for xml raw 
	else if @err='7'
		select 7 as coderr, 'Luna e inchisa din punct de vedere al costurilor!' as msgerr for xml raw 
	else
		select 99 as coderr, ERROR_MESSAGE() as msgerr for xml raw 
end catch

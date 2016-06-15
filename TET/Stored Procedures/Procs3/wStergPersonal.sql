--***
Create procedure wStergPersonal @sesiune varchar(50), @parXML xml
as 

Declare @tip varchar(2), @sub varchar(9), @iDoc int, @ptupdate int, @o_marca varchar(6), @marca varchar(6), @functie varchar(100), @parXMLFunctii xml, 
@cnp varchar(13), @datanasterii datetime, @sex int, @reglucr decimal(5,2), @pCassInd decimal(5,2), @pCasaSan varchar(20), 
@UltMarca varchar(6), @Luna_inch int, @Anul_inch int, @Data datetime, @detalii xml, 
@referinta int, @tabReferinta int, @eroare int, @mesaj varchar(254), @mesajEroare varchar(254), @varmesaj varchar(254)

set @tip=isnull(@parXML.value('(/row/@tip)[1]','varchar(2)'),'')
set @sub=dbo.iauParA('GE','SUBPRO')
set @pCasaSan=dbo.iauParA('PS','CODJUDETA')
set @Luna_inch=dbo.iauParN('PS','LUNA-INCH')
set @Anul_inch=dbo.iauParN('PS','ANUL-INCH')
set @Data=dbo.eom(convert(datetime,convert(char(2),(case when @luna_inch=12 then 1 else @luna_inch+1 end))+'/'+'01'+'/'+convert(char(4),(case when @luna_inch=12 then @Anul_inch+1 else @Anul_inch end)),101))
set @pCassInd=convert(decimal(5,2),dbo.iauParLN(@Data,'PS','CASSIND'))
select @pCassInd=5.5 where @pCassInd=0

begin try  

EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
IF OBJECT_ID('tempdb..#xmlpersonal') IS NOT NULL drop table #xmlpersonal

select marca
into #xmlpersonal
from OPENXML(@iDoc, '/row')
WITH
(
	marca varchar(6) '@marca'
)
	delete p from personal p, #xmlpersonal x
		where p.marca=x.marca
	delete p from infopers p, #xmlpersonal x
		where p.marca=x.marca

end try  

begin catch
	set @mesaj=ERROR_MESSAGE()+' (wStergPersonal)'
	raiserror(@mesaj, 11, 1)
end catch

IF OBJECT_ID('tempdb..#xmlpersonal') IS NOT NULL drop table #xmlpersonal

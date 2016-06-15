create procedure [dbo].[wUAScriuPozCon] @sesiune [varchar](50), @parXML [xml]
WITH EXECUTE AS CALLER
AS
declare @mesajeroare varchar(500),@utilizator char(10), @userASiS varchar(20),@sub char(9),@tip char(2),
	@cod varchar(20),@cantitate float,@pret float,@idcontract int,@numar_pozitie int
   
set @Utilizator=dbo.fIauUtilizatorCurent()  
set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')  

declare @iDoc int
EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML

declare @update int

begin try        
    select
         @update = isnull(@parXML.value('(/row/row/@update)[1]','bit'),0),
         @idcontract = isnull(@parXML.value('(/row/@id_contract)[1]','int'),0),
		 @cod = ltrim(rtrim(isnull(@parXML.value('(/row/row/@cod)[1]','varchar(20)'),''))),
		 @cantitate = isnull(@parXML.value('(/row/row/@cantitate)[1]','float'),0),
    	 @pret = isnull(@parXML.value('(/row/row/@pret)[1]','float'),0),
    	 @numar_pozitie = isnull(@parXML.value('(/row/row/@numar_pozitie)[1]','int'),0)
       
    if exists (select 1 from sys.objects where name='wScriuContracteUASP' and type='P')
		exec wScriuPozConSP @sesiune, @parXML
	else   
	begin
		if @cod not in (select cod from NomenclAbon)
			begin     
				set @mesajeroare='Serviciul introdus nu este valid!'  
				raiserror(@mesajeroare,11,1)  
			end
		--exec wUAValidareAbonatiContr  @parXML   
		if @update=1 
			update uapozcon set Cod=@cod,Pret=@pret,Cantitate=@cantitate 
			where Id_contract=@idcontract and Numar_pozitie=@numar_pozitie
		else
			begin
			set @numar_pozitie=1+isnull((select MAX(numar_pozitie) from uapozcon where Id_contract=@idcontract),0)
			insert into uapozcon select @idcontract,@numar_pozitie,@cod,@cantitate,@pret,round((@cantitate*@pret),2),
				@userASiS,GETDATE(),0,0,'','',''
			end
	end
end try
begin catch
set @mesajeroare = ERROR_MESSAGE()
 raiserror(@mesajeroare, 11, 1)
end catch

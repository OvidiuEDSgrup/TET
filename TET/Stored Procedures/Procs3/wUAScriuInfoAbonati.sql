create PROCEDURE [dbo].[wUAScriuInfoAbonati]  
 @sesiune [varchar](50),  
 @parXML [xml]  
WITH EXECUTE AS CALLER
AS  
set transaction isolation level READ UNCOMMITTED  
  
 Declare  @codabonat varchar(30),@filtrucontract varchar(30),@filtrudenabonat varchar(30),@categorie int,@telefon char(30),
	@inmatriculare char(30),@cod_fiscal char(30),@codbanca char(30),@contbanca char(30),@update int,@mesajeroare varchar(500),
	@utilizator char(10), @userASiS varchar(20),@codpostal varchar(30)
   
set @Utilizator=dbo.fIauUtilizatorCurent()  
set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')  

declare @iDoc int
EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML  

begin try        
    select
        @update = isnull(@parXML.value('(/row/@update)[1]','bit'),0),
        @codabonat=isnull(@parXML.value('(/row/@codabonat)[1]', 'varchar(30)'), ''),
		@categorie=isnull(@parXML.value('(/row/row/@categorie)[1]', 'int'), ''),
		@telefon=ltrim(rtrim(isnull(@parXML.value('(/row/row/@telefon)[1]', 'varchar(30)'), ''))),
		@inmatriculare=ltrim(rtrim(isnull(@parXML.value('(/row/row/@inmatriculare)[1]', 'varchar(30)'), ''))),
		@cod_fiscal=ltrim(rtrim(isnull(@parXML.value('(/row/row/@cod_fiscal)[1]', 'varchar(30)'), ''))),
		@codbanca=ltrim(rtrim(isnull(@parXML.value('(/row/row/@codbanca)[1]', 'varchar(30)'), ''))),
		@contbanca=ltrim(rtrim(isnull(@parXML.value('(/row/row/@contbanca)[1]', 'varchar(30)'), ''))),
		@codpostal=ltrim(rtrim(isnull(@parXML.value('(/row/row/@codpostal)[1]', 'varchar(30)'), '')))

    
    if exists (select 1 from sys.objects where name='wUAScriuInfoAbonatiSP' and type='P')
		exec wUAScriuInfoAbonatiSP @sesiune, @parXML
	else   
	begin
		--exec wUAValidareAbonati  @parXML   
		update abonati set Discount=@categorie,Telefon=@telefon,Inmatriculare=@inmatriculare,Cod_fiscal=@cod_fiscal,
			Banca=@codbanca,Cont_in_Banca=@contbanca,Cod_postal=@codpostal
			where abonat=@codabonat
	end
end try
begin catch
set @mesajeroare = ERROR_MESSAGE()
 raiserror(@mesajeroare, 11, 1)
end catch

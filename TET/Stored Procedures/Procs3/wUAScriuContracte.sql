create procedure [dbo].[wUAScriuContracte] @sesiune [varchar](50), @parXML [xml]
WITH EXECUTE AS CALLER
AS
declare @mesajeroare varchar(500),@utilizator char(10), @userASiS varchar(20),@sub char(9),@tip char(2),
	@codabonat varchar(30),@idcontract int,@contract varchar(30),@data datetime,@lm varchar(20),@stare varchar(10),
	@categpen varchar(10),@categpret varchar(10),@dataexpirarii datetime,@info varchar(10),@modfact int,@primaluna int,
	@scadenta int,@tipcontr varchar(10),@zifacturare int,@datarezilierii datetime,@update int,
	@o_codabonat varchar(30),@o_contract varchar(30),@nrtemp int,@zona varchar(20),@tipcontract varchar(2)

set @Utilizator=dbo.fIauUtilizatorCurent()  
set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')  

declare @iDoc int
EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML

begin try        
    select
         @update = isnull(@parXML.value('(/row/@update)[1]','bit'),0),
         @codabonat = rtrim(ltrim(isnull(@parXML.value('(/row/@codabonat)[1]','varchar(30)'),0))),
         @idcontract = rtrim(ltrim(isnull(@parXML.value('(/row/@id_contract)[1]','int'),0))),
         @contract = rtrim(ltrim(isnull(@parXML.value('(/row/@contract)[1]','varchar(30)'),0))),
         @data = rtrim(ltrim(isnull(@parXML.value('(/row/@datacontract)[1]','datetime'),0))),
         @lm = rtrim(ltrim(isnull(@parXML.value('(/row/@lm)[1]','varchar(20)'),0))),
         @stare = rtrim(ltrim(isnull(@parXML.value('(/row/@stare)[1]','varchar(10)'),0))),
         @categpen = rtrim(ltrim(isnull(@parXML.value('(/row/@categpen)[1]','varchar(10)'),0))),
         @categpret = rtrim(ltrim(isnull(@parXML.value('(/row/@categpret)[1]','varchar(10)'),0))),
         @dataexpirarii = rtrim(ltrim(isnull(@parXML.value('(/row/@dataexpirarii)[1]','datetime'),0))),
         @info = rtrim(ltrim(isnull(@parXML.value('(/row/@info)[1]','varchar(10)'),0))),
         @modfact = rtrim(ltrim(isnull(@parXML.value('(/row/@modfact)[1]','int'),0))),
         @primaluna = rtrim(ltrim(isnull(@parXML.value('(/row/@primaluna)[1]','int'),0))),
         @scadenta = rtrim(ltrim(isnull(@parXML.value('(/row/@scadenta)[1]','int'),0))),
         @tipcontr = rtrim(ltrim(isnull(@parXML.value('(/row/@tipcontr)[1]','varchar(10)'),0))),
         @zifacturare = rtrim(ltrim(isnull(@parXML.value('(/row/@zifacturare)[1]','int'),0))),
         @datarezilierii = rtrim(ltrim(isnull(@parXML.value('(/row/@datarezilierii)[1]','datetime'),0))),
         @zona = rtrim(ltrim(isnull(@parXML.value('(/row/@zona)[1]','varchar(20)'),0))),
         @o_contract = rtrim(ltrim(isnull(@parXML.value('(/row/@o_contract)[1]','varchar(30)'),0))),
         @tipcontract = rtrim(ltrim(isnull(@parXML.value('(/row/@tipcontract)[1]','varchar(2)'),0))),
         @o_codabonat = rtrim(ltrim(isnull(@parXML.value('(/row/@o_codabonat)[1]','varchar(30)'),0)))

    
    if exists (select 1 from sys.objects where name='wScriuContracteUASP' and type='P')
		exec wScriuContracteUASP @sesiune, @parXML
	else   
	begin
	
	
	---------
	set @Utilizator=dbo.fIauUtilizatorCurent()  
	set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')  

	declare @lista_lm int
	set @lista_lm=(case when exists (select 1 from proprietati 
	where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='LOCMUNCA' and Valoare<>'') then 1 else 0 end)

	---------
	
	if (@lista_lm=1 and @lm='') or (@lista_lm=1 and not exists (select cod from lm where Cod=@lm))
		begin     
			set @mesajeroare='Intorduceti un loc de munca valid!!'  
			raiserror(@mesajeroare,11,1)  
		end
	
	if (@lista_lm=1 and not exists (select cod from LMFiltrare where Cod=@lm and utilizator=@utilizator))
		begin     
			set @mesajeroare='Nu aveti drept de operare pentru acest loc de munca!!'  
			raiserror(@mesajeroare,11,1)  
		end
	
		if @modfact=1 set @primaluna=0
		--exec wUAValidareAbonatiContr  @parXML   
		if @update=0
		begin
			if @tipcontract not in ('UC','UK')
				begin     
					set @mesajeroare='Tip contract invalid !'  
					raiserror(@mesajeroare,11,1)  
				end
			if @codabonat not in (select abonat from abonati)
				begin     
					set @mesajeroare='Abonatul introdus nu este valid!'  
					raiserror(@mesajeroare,11,1)  
				end
			/*if @contract in (select contract from uacon where Tip_contract=@tipcontract)
				begin     
					set @mesajeroare='Contractul introdus exista deja!'  
					raiserror(@mesajeroare,11,1)  
				end
			*/
			if @contract=''  
			begin  
				set @nrtemp=0
				if @tipcontract='UC' exec wIauNrDocUA 'UC',@utilizator,'' ,@nrtemp output  
					else exec wIauNrDocUA 'UK',@utilizator,'' ,@nrtemp output  
				if @nrtemp>99999999 or @nrtemp=0
				begin     
					set @mesajeroare='Eroare la obtinerea nr. de contract!'  
					raiserror(@mesajeroare,11,1)  
				end
				else set @contract=(CAST(@nrtemp as CHAR(8)))
			end
			insert into uacon(Contract,Stare,Data,Tip_contract,Tip,abonat,Locatar,Zona,Data_expirarii,Data_rezilierii,Scadenta,Discount,info_contract,Nr_de_angajati,Suprafata,Loc_de_munca,categorie_penalizare,Mod_facturare,Luna_facturare,Ziua_de_facturare,Categorie_pret,Utilizator,Data_operarii,Val1,Val2,Val3,Alfa1,Alfa2,Alfa3,Data1,Data2) 
				select @contract,@stare,@data,@tipcontract,@tipcontr,@codabonat,'',@zona,@dataexpirarii,'',@scadenta,
					0,@info,0,0,@lm,@categpen,@modfact,@primaluna,@zifacturare,@categpret,@userASiS,GETDATE(),0,0,0,'','','','',''
		
		end
		else
		begin
			if @contract<>@o_contract and @contract in (select contract from uacon where tip=@tipcontract) 
				begin     
					set @mesajeroare='Nu se poate schimba numarul de contract!'  
					raiserror(@mesajeroare,11,1)  
				end
			if @codabonat<>@o_codabonat and @o_codabonat in (select abonat from incasarifactabon)
				begin     
					set @mesajeroare='Nu se poate schimba abonatul pe contract!'  
					raiserror(@mesajeroare,11,1)  
				end
			if @stare=3 and @datarezilierii <=@data 
				begin     
					set @mesajeroare='Data rezilierii nu este valida !'  
					raiserror(@mesajeroare,11,1)  
				end
			
			update uacon set Contract=@contract,Tip_contract=@tipcontract,stare=@stare,data=@data,tip=@tipcontr,abonat=@codabonat,zona=@zona,data_expirarii=@dataexpirarii,
				data_rezilierii=@datarezilierii,scadenta=@scadenta,info_contract=@info,loc_de_munca=@lm,
				categorie_penalizare=@categpen,mod_facturare=@modfact,luna_facturare=@primaluna,
				ziua_de_Facturare=@zifacturare,categorie_pret=@categpret where Id_contract=@idcontract

		end
		
	end
end try
begin catch
set @mesajeroare = ERROR_MESSAGE()
 raiserror(@mesajeroare, 11, 1)
end catch

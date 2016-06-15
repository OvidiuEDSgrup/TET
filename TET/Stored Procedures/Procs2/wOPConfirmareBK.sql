--***
create procedure wOPConfirmareBK @sesiune varchar(50), @docXML xml        
as      
    
    
declare @contract char(20)    
set @contract = ISNULL(@docXML.value('(/parametri/@contract)[1]', 'varchar(20)'), '')     
    
--stare 4-Confirmat    
begin try    

if @contract=''
	raiserror('Trebuie sa selectati o comanda de transfer!' ,16,1)

update con    
set Stare = '4'    
where Contract = @contract    
    
declare @subunitate char(9)      
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output     

declare @numars varchar(20)
set  @numars = (select max('I'+right(rtrim(Numar),7)) from pozdoc where Subunitate = @subunitate and tip = 'TE' and rtrim(Factura) = rtrim(@contract))
    
insert into pozdoc(Subunitate,Tip,Numar,Cod,Data,Gestiune,Cantitate,Pret_valuta,Pret_de_stoc,Adaos,
	Pret_vanzare,Pret_cu_amanuntul,TVA_deductibil,Cota_TVA,Utilizator,Data_operarii,Ora_operarii,
	Cod_intrare,Cont_de_stoc,Cont_corespondent,
	TVA_neexigibil,Pret_amanunt_predator,Tip_miscare,
	Locatie,Data_expirarii,Numar_pozitie,Loc_de_munca,Comanda,Barcod,
	Cont_intermediar,Cont_venituri,Discount,Tert,Factura,Gestiune_primitoare,Numar_DVI,
	Stare,Grupa,Cont_factura,Valuta,Curs,Data_facturii,Data_scadentei,Procent_vama,Suprataxe_vama,
	Accize_cumparare,Accize_datorate,Contract,Jurnal) 
select Subunitate,Tip,'I'+right(rtrim(Numar),7),Cod,Data,Gestiune_primitoare,Cantitate,Pret_valuta,Pret_de_stoc,Adaos,Pret_vanzare,Pret_cu_amanuntul,TVA_deductibil,Cota_TVA,Utilizator,convert(datetime,convert(char(10),getdate(),110),110),    
replace(convert(char(8), getdate(),108),':',''),Grupa,Cont_corespondent,Cont_de_stoc,TVA_neexigibil,Pret_amanunt_predator,Tip_miscare,Locatie,Data_expirarii,Numar_pozitie,Loc_de_munca,Comanda,Factura,Cont_intermediar,Cont_venituri,Discount,Tert,'',[contract],Numar_DVI,Stare,Grupa,Cont_factura,Valuta,Curs,Data_facturii,Data_scadentei,Procent_vama,Suprataxe_vama,Accize_cumparare,Accize_datorate,'',Jurnal    
from pozdoc where Subunitate = @subunitate and tip = 'TE' and rtrim(Factura) = rtrim(@contract)       

select 'S-a generat documentul TE cu numarul '+rtrim(@numars)+'I din data '+convert(char(10),GETDATE(),103) as textMesaj for xml raw, root('Mesaje')

end try   
 
    
begin catch 
	declare @eroare varchar(200) 
	set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch

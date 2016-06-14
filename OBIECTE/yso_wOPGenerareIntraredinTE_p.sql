--***
if exists (select * from sysobjects where name ='yso_wOPGenerareIntraredinTE_p')
drop procedure yso_wOPGenerareIntraredinTE_p
go
--***
create procedure [dbo].yso_wOPGenerareIntraredinTE_p @sesiune varchar(50), @parXML xml                
as              
-- procedura de generare TE din TE pentru câte o gestiune de transfer
declare @subunitate char(9),@tip char(2),@numar char(8), @userASiS varchar(20), @gestiune varchar(9), @gestprimTE varchar(9), @gestdestTE varchar(9), 
		@numarTE varchar(8),@err int,@codbare char(1),@data datetime,@gestiunetmp varchar(13),@newdata datetime,@lm varchar(9)

set @numar = ISNULL(@parXML.value('(/*/@numar)[1]', 'varchar(8)'), '')                
set @data = ISNULL(@parXML.value('(/*/@data)[1]', 'datetime'), '')  
set @newdata = GETDATE()
set @gestprimTE = ISNULL(@parXML.value('(/*/@gestprim)[1]', 'varchar(9)'), '')  -- gestiunea pentru care se face generarea
set @gestdestTE = ISNULL(@parXML.value('(/*/@contract)[1]', 'varchar(9)'), '')  -- gestiunea in care se face generarea
set @lm=isnull((select Loc_de_munca from gestcor where Gestiune=@gestprimTE),'')
set @tip = 'TE'
exec wIaUtilizator @sesiune,@userASiS
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output              

select numar=@numar, dataveche=convert(varchar(10),@data,101), datanoua=convert(varchar(10),@newdata,101), gestprim=@gestprimTE, [contract]=@gestdestTE FOR XML RAW
			--from pozdoc p
			--where p.Subunitate=@subunitate and p.tip='TE' and p.Numar=@numar and data=@data --and Gestiune_primitoare=@gestprimTE 
			--	and Tip_miscare='E' for XML raw


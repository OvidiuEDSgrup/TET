IF  EXISTS (select * from sysobjects where name ='validFacturaSP')
	DROP PROCEDURE validFacturaSP
GO
create procedure validFacturaSP
as
begin try
	/*	Se lucreaza cu #facturi (tert, tip, factura, data)	*/
	declare
		@err varchar(1000)

	IF EXISTS (select 1 from facturi f JOIN #facturi df on f.tert=df.tert and f.factura=df.factura and df.tip=(case f.tip when 0x54 then 'F' else 'B' end) --and f.data<>df.data
		and rtrim(f.Factura)='')
	begin
		delete f
		from facturi f JOIN #facturi df on f.tert=df.tert and f.factura=df.factura and df.tip=(case f.tip when 0x54 then 'F' else 'B' end) --and f.data<>df.data
		and rtrim(f.Factura)=''
		--RAISERROR(@err, 16, 1)
	end
		
end try
BEGIN CATCH
	declare
		@mesaj varchar(500)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
END CATCH
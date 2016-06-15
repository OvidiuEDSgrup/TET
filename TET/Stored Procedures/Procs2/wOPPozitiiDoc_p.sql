
create procedure wOPPozitiiDoc_p @sesiune varchar(50), @parXML xml
as

declare @poz xml, @par xml

select @par=@parxml.query('/row/parametri')
set @par.modify('delete (/parametri/factura)[1]')

set @poz = (
				select	t.c.value('@cod','varchar(20)') codfurnizor, 
						rtrim(p.Cod_resursa) cod,
						rtrim(t.c.value('@denumire','varchar(100)')) denumire,
						convert(decimal(18,3),t.c.value('@cantitate','float')) cantitate,
						convert(decimal(18,5),t.c.value('@pretfaraTVA','float')) pretfaraTVA,
						convert(decimal(18,2),t.c.value('@TVApepozitie','float')) TVApepozitie,
						1 as selectare, 
						@par
				from @parXML.nodes('row/parametri/factura/pozitie') t(c)
				left join ppreturi p on p.Tert=@parXML.value('(/row/parametri/factura/@CUIfurnizor)[1]','varchar(20)')
							and CodFurn=t.c.value('@cod','varchar(20)')
				for xml raw,type
			)

			select @parXML

			select	t.c.value('@cod','varchar(20)') codfurnizor, 
						rtrim(p.Cod_resursa) cod,
						rtrim(t.c.value('@denumire','varchar(100)')) denumire,
						convert(decimal(18,3),t.c.value('@cantitate','float')) cantitate,
						convert(decimal(18,5),t.c.value('@pretfaraTVA','float')) pretfaraTVA,
						convert(decimal(18,2),t.c.value('@TVApepozitie','float')) TVApepozitie,
						1 as selectare,
						@par
				from @parXML.nodes('row/parametri/factura/pozitie') t(c)
				left join ppreturi p on rtrim(p.Tert)=(select max(tert) from terti where cod_fiscal=rtrim(@parXML.value('(/row/parametri/factura/@CUIfurnizor)[1]','varchar(20)')))
							and rtrim(CodFurn)=rtrim(t.c.value('@codfurnizor','varchar(20)'))

select @poz for xml path('DateGrid'),root('Mesaje')

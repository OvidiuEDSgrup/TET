exec sp_executesql N'EXEC rapFormReceptieAmSP @sesiune=@sesiune, @tip=@tip, @numar=@numar, @data=@data, @datajos=@datajos, @datasus=@datasus, @f_gestprim=@f_gestprim, @parXML=@parXML',N'@sesiune nvarchar(13),@tip nvarchar(2),@numar nvarchar(7),@data datetime,@datajos nvarchar(4000),@datasus nvarchar(4000),@f_gestprim nvarchar(4000),@parXML nvarchar(4000)',@sesiune=N'',@tip=N'TE',@numar=N'GL70001',@data='2014-05-27 00:00:00',@datajos=NULL,@datasus=NULL,@f_gestprim=NULL,@parXML=NULL

select p.detalii,p.Gestiune_primitoare,* from pozdoc p where p.Numar like 'GL70001' and p.Data='2014-05-27'
and p.Factura like 'GL980447'
select * from doc p where p.Numar like 'GL70001'  and p.Factura like 'GL980447'
--order by 1,2
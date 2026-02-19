#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Script para generar informe PDF sobre la utilidad de la Vista de Refutar Errores
Fecha: Febrero 2026
"""

from reportlab.lib.pagesizes import letter, A4
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import (
    SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer,
    PageBreak, Image, KeepTogether, PageTemplate, Frame
)
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_JUSTIFY, TA_RIGHT
from datetime import datetime
import os

class InformeRefutarErrores:
    def __init__(self, filename="Informe_Refutar_Errores.pdf"):
        self.filename = filename
        self.pagesize = A4
        self.width, self.height = self.pagesize
        self.styles = getSampleStyleSheet()
        self._create_custom_styles()
        
    def _create_custom_styles(self):
        """Crea estilos personalizados para el informe"""
        self.styles.add(ParagraphStyle(
            name='CustomTitle',
            parent=self.styles['Heading1'],
            fontSize=28,
            textColor=colors.HexColor('#1A237E'),
            spaceAfter=6,
            alignment=TA_CENTER,
            fontName='Helvetica-Bold'
        ))
        
        self.styles.add(ParagraphStyle(
            name='CustomHeading2',
            parent=self.styles['Heading2'],
            fontSize=14,
            textColor=colors.HexColor('#1A237E'),
            spaceAfter=12,
            spaceBefore=12,
            fontName='Helvetica-Bold',
            borderColor=colors.HexColor('#1A237E'),
            borderWidth=2,
            borderPadding=10,
            backColor=colors.HexColor('#E8EAF6')
        ))
        
        self.styles.add(ParagraphStyle(
            name='BodyJustified',
            parent=self.styles['BodyText'],
            fontSize=11,
            alignment=TA_JUSTIFY,
            spaceAfter=12
        ))
        
        self.styles.add(ParagraphStyle(
            name='Subtitle',
            parent=self.styles['Normal'],
            fontSize=12,
            textColor=colors.HexColor('#424242'),
            spaceAfter=12,
            alignment=TA_CENTER,
            fontName='Helvetica-Oblique'
        ))
        
        self.styles.add(ParagraphStyle(
            name='BenefitTitle',
            parent=self.styles['Heading3'],
            fontSize=12,
            textColor=colors.HexColor('#FFFFFF'),
            backColor=colors.HexColor('#1A237E'),
            spaceAfter=6,
            fontName='Helvetica-Bold',
            leftIndent=10
        ))
    
    def _create_header(self, story):
        """Crea el encabezado del informe"""
        # Título principal
        story.append(Paragraph(
            "INFORME DE UTILIDAD",
            self.styles['CustomTitle']
        ))
        story.append(Paragraph(
            "Vista de Refutar Errores - Sistema Lectra",
            self.styles['CustomTitle']
        ))
        
        story.append(Spacer(1, 0.2*inch))
        
        # Subtítulo con fecha
        story.append(Paragraph(
            f"Febrero 2026 | Alcance: 378 dispositivos (100% de cobertura)",
            self.styles['Subtitle']
        ))
        
        story.append(Spacer(1, 0.3*inch))
        
        # Línea divisora
        story.append(Table(
            [['']],
            colWidths=[7*inch],
            style=TableStyle([
                ('LINEBELOW', (0, 0), (-1, -1), 2, colors.HexColor('#1A237E')),
            ])
        ))
        
        story.append(Spacer(1, 0.3*inch))
    
    def _create_executive_summary(self, story):
        """Crea el resumen ejecutivo"""
        story.append(Paragraph("RESUMEN EJECUTIVO", self.styles['CustomHeading2']))
        
        # Contenedor con información clave
        summary_data = [
            ['Dispositivos Instalados', '378'],
            ['Cobertura de Planta', '100%'],
            ['Personal Cubierto', 'Auxiliares, Supervisores, Personal Administrativo'],
            ['Módulo Principal', 'Gestión y Refutación de Errores de Lectura'],
            ['Estado', 'Operativo y en Producción']
        ]
        
        summary_table = Table(summary_data, colWidths=[2.5*inch, 4.5*inch])
        summary_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (0, -1), colors.HexColor('#E8EAF6')),
            ('BACKGROUND', (1, 0), (1, -1), colors.HexColor('#F5F5F5')),
            ('TEXTCOLOR', (0, 0), (0, -1), colors.HexColor('#1A237E')),
            ('TEXTCOLOR', (1, 0), (1, -1), colors.HexColor('#212121')),
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('FONTNAME', (0, 0), (0, -1), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, -1), 11),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 12),
            ('TOPPADDING', (0, 0), (-1, -1), 12),
            ('GRID', (0, 0), (-1, -1), 1, colors.HexColor('#BDBDBD')),
        ]))
        
        story.append(summary_table)
        story.append(Spacer(1, 0.3*inch))
    
    def _create_description(self, story):
        """Crea la descripción del módulo"""
        story.append(Paragraph("1. DESCRIPCIÓN DEL MÓDULO", self.styles['CustomHeading2']))
        
        description = """
        La <b>Vista de Refutar Errores</b> es un módulo integral del sistema Lectra diseñado específicamente 
        para permitir que el personal operativo (lectores, supervisores auxiliares y personal administrativo) 
        revise, valide y refute errores detectados durante el proceso de lectura automática de medidores. 
        Este módulo proporciona una interfaz intuitiva y eficiente para gestionar discrepancias en los datos 
        de consumo registrados.
        """
        
        story.append(Paragraph(description, self.styles['BodyJustified']))
        story.append(Spacer(1, 0.2*inch))
    
    def _create_functionality(self, story):
        """Crea la sección de funcionalidades"""
        story.append(Paragraph("2. FUNCIONALIDADES PRINCIPALES", self.styles['CustomHeading2']))
        
        functionalities = [
            ("Listado de Errores Pendientes", 
             "Muestra de forma clara y organizada todos los errores de lectura asignados al usuario logueado, con información de dirección, instalación y consumo anómalo."),
            
            ("Indicadores Visuales de Estado", 
             "Sistema de colores y iconos que permite identificar rápidamente qué errores han sido refutados (con evidencia fotográfica) y cuáles están pendientes."),
            
            ("Edición y Refutación de Errores", 
             "Interface intuitiva para editar errores, agregar comentarios detallados y adjuntar evidencia fotográfica que respalde la refutación."),
            
            ("Validación de Sesión", 
             "Mecanismo de seguridad que garantiza que solo usuarios autenticados accedan a la información sensible de errores."),
            
            ("Actualización en Tiempo Real", 
             "Función de refresh que permite obtener la información más actualizada sin necesidad de reiniciar la aplicación."),
            
            ("Sincronización Automática", 
             "Los cambios realizados se guardan automáticamente en la base de datos centralizada para mantener coherencia entre los 378 dispositivos.")
        ]
        
        for title, description in functionalities:
            # Crear tabla con viñeta
            func_table = Table(
                [['•', Paragraph(f"<b>{title}:</b> {description}", self.styles['BodyText'])]],
                colWidths=[0.3*inch, 6.7*inch]
            )
            func_table.setStyle(TableStyle([
                ('VALIGN', (0, 0), (-1, -1), 'TOP'),
                ('LEFTPADDING', (1, 0), (1, 0), 10),
            ]))
            story.append(func_table)
            story.append(Spacer(1, 0.15*inch))
        
        story.append(Spacer(1, 0.2*inch))
    
    def _create_benefits(self, story):
        """Crea la sección de beneficios"""
        story.append(Paragraph("3. BENEFICIOS OPERATIVOS", self.styles['CustomHeading2']))
        
        benefits = [
            {
                'title': 'Reducción de Errores en Lectura',
                'icon': '✓',
                'description': 'Permite al personal operativo identificar y refutar inconsistencias antes de que afecten la facturación, mejorando la calidad de los datos.'
            },
            {
                'title': 'Aumento de Eficiencia del Personal',
                'icon': '⚡',
                'description': 'Interface amigable y directa que reduce el tiempo necesario para procesar y documentar refutaciones de errores.'
            },
            {
                'title': 'Trazabilidad y Auditoría',
                'icon': '📋',
                'description': 'Registro completo de todas las acciones, evidencia fotográfica y comentarios para auditoría y trazabilidad de procesos.'
            },
            {
                'title': 'Cobertura Integral',
                'icon': '🎯',
                'description': 'Con 378 dispositivos instalados, el 100% de la planta (auxiliares, supervisores y administrativos) puede gestionar errores desde cualquier ubicación.'
            },
            {
                'title': 'Mejora en Relaciones con Clientes',
                'icon': '💡',
                'description': 'Respuestas rápidas y documentadas a reclamos de clientes gracias a la refutación temprana de errores potenciales.'
            },
            {
                'title': 'Adaptabilidad Operativa',
                'icon': '🔄',
                'description': 'El sistema se adapta a diferentes roles (auxiliares, supervisores, administrativos) con permisos y vistas especializadas.'
            }
        ]
        
        for idx, benefit in enumerate(benefits, 1):
            # Crear tabla para cada beneficio
            benefit_data = [[
                Paragraph(f"<font size=16><b>{benefit['icon']}</b></font>", self.styles['Normal']),
                Paragraph(f"<b>{benefit['title']}</b><br/>{benefit['description']}", self.styles['BodyText'])
            ]]
            
            benefit_table = Table(benefit_data, colWidths=[0.5*inch, 6.5*inch])
            benefit_table.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (0, 0), colors.HexColor('#E8EAF6')),
                ('VALIGN', (0, 0), (-1, -1), 'TOP'),
                ('LEFTPADDING', (1, 0), (1, 0), 10),
                ('RIGHTPADDING', (0, 0), (0, 0), 10),
                ('ALIGNMENT', (0, 0), (0, 0), 'CENTER'),
            ]))
            
            story.append(benefit_table)
            story.append(Spacer(1, 0.15*inch))
        
        story.append(Spacer(1, 0.2*inch))
    
    def _create_impact(self, story):
        """Crea la sección de impacto"""
        story.append(Paragraph("4. IMPACTO EN LA OPERACIÓN", self.styles['CustomHeading2']))
        
        impact_text = """
        <b>Alcance Organizacional:</b> La implementación de la Vista de Refutar Errores 
        en 378 dispositivos representa una cobertura del <b>100% de toda la planta de lectura</b>, 
        incluyendo:
        """
        
        story.append(Paragraph(impact_text, self.styles['BodyJustified']))
        story.append(Spacer(1, 0.1*inch))
        
        # Roles cubiertos
        roles_data = [
            ['Personal', 'Descripción', 'Beneficio Principal'],
            ['Auxiliares de Lectura', 'Personal de campo responsable de lecturas iniciales', 'Refutación rápida de anomalías detectadas'],
            ['Supervisores', 'Revisión y validación de lecturas de su zona', 'Control de calidad integral en tiempo real'],
            ['Personal Administrativo', 'Gestión centralizada y reportes de errores', 'Análisis profundo y seguimiento de patrones']
        ]
        
        roles_table = Table(roles_data, colWidths=[1.5*inch, 2.5*inch, 2.5*inch])
        roles_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#1A237E')),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 10),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
            ('BACKGROUND', (0, 1), (-1, -1), colors.HexColor('#F5F5F5')),
            ('GRID', (0, 0), (-1, -1), 1, colors.HexColor('#BDBDBD')),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('FONTSIZE', (0, 1), (-1, -1), 10),
        ]))
        
        story.append(roles_table)
        story.append(Spacer(1, 0.2*inch))
    
    def _create_metrics(self, story):
        """Crea la sección de métricas de desempeño"""
        story.append(Paragraph("5. MÉTRICAS DE DESEMPEÑO", self.styles['CustomHeading2']))
        
        metrics_text = """
        El módulo de Refutar Errores ha demostrado ser una herramienta efectiva para mejorar 
        la calidad operativa. Las siguientes métricas caracterizan su desempeño:
        """
        
        story.append(Paragraph(metrics_text, self.styles['BodyJustified']))
        story.append(Spacer(1, 0.15*inch))
        
        # Tabla de métricas
        metrics_data = [
            ['Métrica', 'Valor', 'Estado'],
            ['Dispositivos Operativos', '378/378 (100%)', '✓ Óptimo'],
            ['Cobertura de Planta', '100%', '✓ Completa'],
            ['Usuarios Activos', '378 (potenciales)', '✓ Alcance Total'],
            ['Disponibilidad del Sistema', '24/7', '✓ Continua'],
            ['Sincronización de Base Datos', 'Real-time', '✓ Inmediata'],
            ['Validación de Sesión', 'Automática', '✓ Segura']
        ]
        
        metrics_table = Table(metrics_data, colWidths=[2.5*inch, 2.5*inch, 1.5*inch])
        metrics_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#1A237E')),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 10),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
            ('BACKGROUND', (0, 1), (-1, -1), colors.HexColor('#F5F5F5')),
            ('GRID', (0, 0), (-1, -1), 1, colors.HexColor('#BDBDBD')),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('FONTSIZE', (0, 1), (-1, -1), 10),
        ]))
        
        story.append(metrics_table)
        story.append(Spacer(1, 0.2*inch))
    
    def _create_technical_specs(self, story):
        """Crea la sección de especificaciones técnicas"""
        story.append(Paragraph("6. ESPECIFICACIONES TÉCNICAS", self.styles['CustomHeading2']))
        
        specs_text = """
        <b>Plataforma:</b> Flutter<br/>
        <b>Backend:</b> Supabase<br/>
        <b>Sincronización:</b> PostgreSQL en tiempo real<br/>
        <b>Autenticación:</b> Session Token Validation<br/>
        <b>Almacenamiento:</b> Cloud Storage (Evidencia Fotográfica)<br/>
        <b>Interfaz:</b> Responsive Design (Material Design 3)<br/>
        """
        
        story.append(Paragraph(specs_text, self.styles['BodyJustified']))
        story.append(Spacer(1, 0.2*inch))
    
    def _create_recommendations(self, story):
        """Crea la sección de recomendaciones"""
        story.append(Paragraph("7. RECOMENDACIONES", self.styles['CustomHeading2']))
        
        recommendations = [
            "Mantener capacitación continua del personal en el uso del módulo para maximizar su utilidad.",
            "Realizar análisis periódicos de patrones de errores para identificar áreas de mejora en procesos.",
            "Implementar dashboards analíticos que consoliden datos de refutaciones para seguimiento gerencial.",
            "Establecer protocolos de SLA para tiempo de respuesta en refutación de errores.",
            "Integrar resultados de refutación en programas de desempeño del personal.",
            "Dotar al personal administrativo de reportes ejecutivos automáticos basados en datos de refutación."
        ]
        
        for idx, rec in enumerate(recommendations, 1):
            rec_table = Table(
                [['', Paragraph(rec, self.styles['BodyText'])]],
                colWidths=[0.3*inch, 6.7*inch]
            )
            rec_table.setStyle(TableStyle([
                ('VALIGN', (0, 0), (-1, -1), 'TOP'),
                ('LEFTPADDING', (1, 0), (1, 0), 10),
            ]))
            story.append(rec_table)
            story.append(Spacer(1, 0.12*inch))
        
        story.append(Spacer(1, 0.3*inch))
    
    def _create_conclusion(self, story):
        """Crea la conclusión del informe"""
        story.append(Paragraph("CONCLUSIÓN", self.styles['CustomHeading2']))
        
        conclusion = """
        La <b>Vista de Refutar Errores</b> representa una solución tecnológica robusta y completa 
        que ha sido implementada exitosamente en toda la planta de lectura de Lectra. Con una cobertura 
        del 100% en 378 dispositivos, el sistema proporciona:
        <br/><br/>
        • <b>Eficiencia Operativa:</b> Reducción significativa en tiempos de procesamiento de errores.
        <br/>
        • <b>Calidad de Datos:</b> Mejora en la integridad y confiabilidad de la información de consumo.
        <br/>
        • <b>Seguridad Informática:</b> Autenticación robusta y validación de sesiones.
        <br/>
        • <b>Escalabilidad:</b> Arquitectura que soporta el crecimiento futuro sin comprometer rendimiento.
        <br/>
        • <b>Accesibilidad:</b> Interfaz intuitiva acesible a todo tipo de usuario operativo.
        <br/><br/>
        El módulo ha probado ser una herramienta indispensable para la operación diaria 
        y continuará siendo un activo clave en mejorar la excelencia operativa de Lectra.
        """
        
        story.append(Paragraph(conclusion, self.styles['BodyJustified']))
        story.append(Spacer(1, 0.3*inch))
    
    def _create_footer(self, story):
        """Crea el pie de página del informe"""
        story.append(PageBreak())
        
        footer_data = [
            [f'Informe Generado: {datetime.now().strftime("%d de %B de %Y - %H:%M:%S")}<br/>Sistema Lectra - Vista de Refutar Errores']
        ]
        
        footer_table = Table(footer_data, colWidths=[7*inch])
        footer_table.setStyle(TableStyle([
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('TEXTCOLOR', (0, 0), (-1, -1), colors.HexColor('#757575')),
            ('FONTSIZE', (0, 0), (-1, -1), 9),
            ('TOPPADDING', (0, 0), (-1, -1), 12),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 12),
        ]))
        
        story.append(footer_table)
    
    def generate(self):
        """Genera el informe PDF"""
        story = []
        
        # Agregar secciones
        self._create_header(story)
        self._create_executive_summary(story)
        self._create_description(story)
        self._create_functionality(story)
        self._create_benefits(story)
        story.append(PageBreak())
        self._create_impact(story)
        self._create_metrics(story)
        self._create_technical_specs(story)
        self._create_recommendations(story)
        self._create_conclusion(story)
        self._create_footer(story)
        
        # Generar PDF
        doc = SimpleDocTemplate(
            self.filename,
            pagesize=self.pagesize,
            rightMargin=0.6*inch,
            leftMargin=0.6*inch,
            topMargin=0.8*inch,
            bottomMargin=0.8*inch
        )
        
        doc.build(story)
        
        return self.filename

def main():
    """Función principal"""
    print("=" * 60)
    print("GENERADOR DE INFORME - REFUTAR ERRORES")
    print("=" * 60)
    print()
    
    # Crear y generar informe
    informe = InformeRefutarErrores()
    
    print("[*] Generando informe PDF...")
    filename = informe.generate()
    
    if os.path.exists(filename):
        file_size = os.path.getsize(filename) / 1024  # Tamaño en KB
        print(f"[OK] Informe generado exitosamente: {filename}")
        print(f"[OK] Tamaño del archivo: {file_size:.2f} KB")
        print()
        print("=" * 60)
    else:
        print("[ERROR] No se pudo generar el informe")

if __name__ == '__main__':
    main()

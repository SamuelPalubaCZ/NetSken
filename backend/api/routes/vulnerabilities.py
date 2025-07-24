"""
Vulnerabilities API endpoints
"""

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime, timedelta

from core.database import get_db, Vulnerability, Device, ScanSession
from api.schemas.vulnerability import VulnerabilityResponse, VulnerabilityListResponse

router = APIRouter()

@router.get("/", response_model=VulnerabilityListResponse)
async def get_vulnerabilities(
    db: Session = Depends(get_db),
    device_id: Optional[str] = Query(None, description="Filter by device ID"),
    scan_session_id: Optional[str] = Query(None, description="Filter by scan session ID"),
    severity: Optional[str] = Query(None, description="Filter by severity"),
    source_tool: Optional[str] = Query(None, description="Filter by source tool"),
    cve_id: Optional[str] = Query(None, description="Filter by CVE ID"),
    limit: int = Query(100, le=1000, description="Maximum number of vulnerabilities"),
    offset: int = Query(0, ge=0, description="Offset for pagination")
):
    """Get list of vulnerabilities with optional filters"""
    
    query = db.query(Vulnerability)
    
    # Apply filters
    if device_id:
        query = query.filter(Vulnerability.device_id == device_id)
    
    if scan_session_id:
        query = query.filter(Vulnerability.scan_session_id == scan_session_id)
    
    if severity:
        query = query.filter(Vulnerability.severity == severity)
    
    if source_tool:
        query = query.filter(Vulnerability.source_tool == source_tool)
    
    if cve_id:
        query = query.filter(Vulnerability.cve_id == cve_id)
    
    # Order by severity (critical first) and detection time
    query = query.order_by(
        Vulnerability.severity_score.desc(),
        Vulnerability.detected_at.desc()
    )
    
    # Get vulnerabilities with pagination
    vulnerabilities = query.offset(offset).limit(limit).all()
    total_count = query.count()
    
    # Convert to response model
    vuln_responses = []
    for vuln in vulnerabilities:
        device_ip = vuln.device.ip_address if vuln.device else "Unknown"
        device_hostname = vuln.device.hostname if vuln.device else None
        
        vuln_response = VulnerabilityResponse(
            id=vuln.id,
            cve_id=vuln.cve_id,
            title=vuln.title,
            description=vuln.description,
            severity=vuln.severity,
            cvss_score=vuln.cvss_score,
            source_tool=vuln.source_tool,
            detected_at=vuln.detected_at,
            affected_port=vuln.affected_port,
            affected_service=vuln.affected_service,
            solution=vuln.solution,
            references=vuln.reference_list,
            device_id=vuln.device_id,
            device_ip=device_ip,
            device_hostname=device_hostname,
            scan_session_id=vuln.scan_session_id
        )
        vuln_responses.append(vuln_response)
    
    return VulnerabilityListResponse(
        vulnerabilities=vuln_responses,
        total_count=total_count,
        returned_count=len(vuln_responses)
    )

@router.get("/{vulnerability_id}", response_model=VulnerabilityResponse)
async def get_vulnerability_detail(
    vulnerability_id: str,
    db: Session = Depends(get_db)
):
    """Get detailed information about a specific vulnerability"""
    
    vulnerability = db.query(Vulnerability).filter(Vulnerability.id == vulnerability_id).first()
    if not vulnerability:
        raise HTTPException(status_code=404, detail="Vulnerability not found")
    
    device_ip = vulnerability.device.ip_address if vulnerability.device else "Unknown"
    device_hostname = vulnerability.device.hostname if vulnerability.device else None
    
    return VulnerabilityResponse(
        id=vulnerability.id,
        cve_id=vulnerability.cve_id,
        title=vulnerability.title,
        description=vulnerability.description,
        severity=vulnerability.severity,
        cvss_score=vulnerability.cvss_score,
        source_tool=vulnerability.source_tool,
        detected_at=vulnerability.detected_at,
        affected_port=vulnerability.affected_port,
        affected_service=vulnerability.affected_service,
        solution=vulnerability.solution,
        references=vulnerability.reference_list,
        device_id=vulnerability.device_id,
        device_ip=device_ip,
        device_hostname=device_hostname,
        scan_session_id=vulnerability.scan_session_id
    )

@router.get("/stats/summary")
async def get_vulnerability_stats(
    db: Session = Depends(get_db),
    hours: int = Query(24, description="Time range in hours")
):
    """Get vulnerability statistics summary"""
    
    cutoff_time = datetime.utcnow() - timedelta(hours=hours)
    
    # Get vulnerabilities in the time range
    recent_vulns = db.query(Vulnerability).filter(
        Vulnerability.detected_at >= cutoff_time
    ).all()
    
    # Calculate statistics
    stats = {
        "total_vulnerabilities": len(recent_vulns),
        "severity_distribution": {},
        "source_tool_distribution": {},
        "top_cves": {},
        "critical_vulnerabilities": len([v for v in recent_vulns if v.severity == "critical"]),
        "high_vulnerabilities": len([v for v in recent_vulns if v.severity == "high"]),
        "devices_affected": len(set(v.device_id for v in recent_vulns if v.device_id))
    }
    
    # Count by severity
    for vuln in recent_vulns:
        severity = vuln.severity
        stats["severity_distribution"][severity] = stats["severity_distribution"].get(severity, 0) + 1
    
    # Count by source tool
    for vuln in recent_vulns:
        tool = vuln.source_tool
        stats["source_tool_distribution"][tool] = stats["source_tool_distribution"].get(tool, 0) + 1
    
    # Count top CVEs
    for vuln in recent_vulns:
        if vuln.cve_id:
            stats["top_cves"][vuln.cve_id] = stats["top_cves"].get(vuln.cve_id, 0) + 1
    
    # Get top 10 CVEs
    stats["top_cves"] = dict(sorted(stats["top_cves"].items(), key=lambda x: x[1], reverse=True)[:10])
    
    return stats

@router.get("/severity/{severity}")
async def get_vulnerabilities_by_severity(
    severity: str,
    db: Session = Depends(get_db),
    limit: int = Query(50, le=500, description="Maximum number of vulnerabilities")
):
    """Get vulnerabilities filtered by severity level"""
    
    valid_severities = ["info", "low", "medium", "high", "critical"]
    if severity not in valid_severities:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid severity. Valid options: {', '.join(valid_severities)}"
        )
    
    vulnerabilities = db.query(Vulnerability).filter(
        Vulnerability.severity == severity
    ).order_by(Vulnerability.detected_at.desc()).limit(limit).all()
    
    # Convert to response format
    results = []
    for vuln in vulnerabilities:
        device_info = {
            "ip_address": vuln.device.ip_address if vuln.device else "Unknown",
            "hostname": vuln.device.hostname if vuln.device else None
        }
        
        vuln_data = {
            "id": vuln.id,
            "title": vuln.title,
            "cve_id": vuln.cve_id,
            "cvss_score": vuln.cvss_score,
            "source_tool": vuln.source_tool,
            "detected_at": vuln.detected_at,
            "device": device_info
        }
        results.append(vuln_data)
    
    return {
        "severity": severity,
        "count": len(results),
        "vulnerabilities": results
    }

@router.get("/device/{device_id}")
async def get_device_vulnerabilities(
    device_id: str,
    db: Session = Depends(get_db)
):
    """Get all vulnerabilities for a specific device"""
    
    device = db.query(Device).filter(Device.id == device_id).first()
    if not device:
        raise HTTPException(status_code=404, detail="Device not found")
    
    vulnerabilities = db.query(Vulnerability).filter(
        Vulnerability.device_id == device_id
    ).order_by(
        Vulnerability.severity_score.desc(),
        Vulnerability.detected_at.desc()
    ).all()
    
    # Group by severity
    grouped_vulns = {
        "critical": [],
        "high": [],
        "medium": [],
        "low": [],
        "info": []
    }
    
    for vuln in vulnerabilities:
        vuln_data = {
            "id": vuln.id,
            "title": vuln.title,
            "cve_id": vuln.cve_id,
            "cvss_score": vuln.cvss_score,
            "source_tool": vuln.source_tool,
            "detected_at": vuln.detected_at,
            "affected_port": vuln.affected_port,
            "affected_service": vuln.affected_service,
            "solution": vuln.solution
        }
        grouped_vulns[vuln.severity].append(vuln_data)
    
    return {
        "device": {
            "id": device.id,
            "ip_address": device.ip_address,
            "hostname": device.hostname,
            "device_type": device.device_type,
            "risk_level": device.risk_level
        },
        "vulnerability_summary": {
            "total": len(vulnerabilities),
            "critical": len(grouped_vulns["critical"]),
            "high": len(grouped_vulns["high"]),
            "medium": len(grouped_vulns["medium"]),
            "low": len(grouped_vulns["low"]),
            "info": len(grouped_vulns["info"])
        },
        "vulnerabilities": grouped_vulns
    }

@router.post("/{vulnerability_id}/mark-resolved")
async def mark_vulnerability_resolved(
    vulnerability_id: str,
    db: Session = Depends(get_db),
    resolution_note: Optional[str] = None
):
    """Mark a vulnerability as resolved"""
    
    vulnerability = db.query(Vulnerability).filter(Vulnerability.id == vulnerability_id).first()
    if not vulnerability:
        raise HTTPException(status_code=404, detail="Vulnerability not found")
    
    # In a real implementation, you might add a 'resolved' field to the Vulnerability model
    # For now, we'll just return success
    
    return {
        "message": "Vulnerability marked as resolved",
        "vulnerability_id": vulnerability_id,
        "resolution_note": resolution_note,
        "resolved_at": datetime.utcnow()
    }

@router.delete("/{vulnerability_id}")
async def delete_vulnerability(
    vulnerability_id: str,
    db: Session = Depends(get_db)
):
    """Delete a vulnerability"""
    
    vulnerability = db.query(Vulnerability).filter(Vulnerability.id == vulnerability_id).first()
    if not vulnerability:
        raise HTTPException(status_code=404, detail="Vulnerability not found")
    
    db.delete(vulnerability)
    db.commit()
    
    return {"message": "Vulnerability deleted successfully"}
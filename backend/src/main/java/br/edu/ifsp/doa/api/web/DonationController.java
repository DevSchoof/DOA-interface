package br.edu.ifsp.doa.api.web;

import br.edu.ifsp.doa.api.security.AuthUser;
import br.edu.ifsp.doa.api.service.ChatService;
import br.edu.ifsp.doa.api.service.DonationService;
import br.edu.ifsp.doa.api.service.PhotoService;
import br.edu.ifsp.doa.api.web.dto.DonationDtos.DonationRequest;
import br.edu.ifsp.doa.api.web.dto.DonationDtos.DonationResponse;
import br.edu.ifsp.doa.api.web.dto.MiscDtos.MessageRequest;
import br.edu.ifsp.doa.api.web.dto.MiscDtos.MessageResponse;
import jakarta.validation.Valid;
import java.util.List;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/donations")
public class DonationController {
    private final DonationService donations;
    private final ChatService chat;
    private final PhotoService photos;

    public DonationController(DonationService donations, ChatService chat, PhotoService photos) {
        this.donations = donations;
        this.chat = chat;
        this.photos = photos;
    }

    // ----- doador -----

    @PostMapping
    @PreAuthorize("hasRole('DONOR')")
    @ResponseStatus(HttpStatus.CREATED)
    public DonationResponse create(@AuthenticationPrincipal AuthUser user, @Valid @RequestBody DonationRequest request) {
        return donations.create(user, request);
    }

    @GetMapping("/mine")
    @PreAuthorize("hasRole('DONOR')")
    public List<DonationResponse> mine(@AuthenticationPrincipal AuthUser user) {
        return donations.listMine(user);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('DONOR')")
    public DonationResponse update(@AuthenticationPrincipal AuthUser user, @PathVariable Long id,
                                   @Valid @RequestBody DonationRequest request) {
        return donations.update(user, id, request);
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('DONOR')")
    public ResponseEntity<Void> delete(@AuthenticationPrincipal AuthUser user, @PathVariable Long id) {
        donations.delete(user, id);
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/{id}/cancel")
    @PreAuthorize("hasRole('DONOR')")
    public DonationResponse cancel(@AuthenticationPrincipal AuthUser user, @PathVariable Long id) {
        return donations.cancel(user, id);
    }

    /** Envia uma foto (multipart, campo "file"; JPEG/PNG/WebP até 5 MB; máx. 5 por doação). */
    @PostMapping(value = "/{id}/photos", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasRole('DONOR')")
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, String> addPhoto(@AuthenticationPrincipal AuthUser user, @PathVariable Long id,
                                        @RequestParam("file") MultipartFile file) {
        return Map.of("url", photos.add(user, id, file));
    }

    @DeleteMapping("/{id}/photos/{photoId}")
    @PreAuthorize("hasRole('DONOR')")
    public ResponseEntity<Void> removePhoto(@AuthenticationPrincipal AuthUser user, @PathVariable Long id,
                                            @PathVariable String photoId) {
        photos.remove(user, id, photoId);
        return ResponseEntity.noContent().build();
    }

    // ----- instituição -----

    /** lat/lng: posição atual do aparelho (GPS). Sem elas, usa a localização cadastrada da instituição. */
    @GetMapping
    @PreAuthorize("hasRole('INSTITUTION')")
    public List<DonationResponse> search(@AuthenticationPrincipal AuthUser user,
                                         @RequestParam(required = false) Long categoryId,
                                         @RequestParam(required = false) Double radiusKm,
                                         @RequestParam(required = false) Double lat,
                                         @RequestParam(required = false) Double lng) {
        return donations.search(user, categoryId, radiusKm, lat, lng);
    }

    @GetMapping("/requested")
    @PreAuthorize("hasRole('INSTITUTION')")
    public List<DonationResponse> requested(@AuthenticationPrincipal AuthUser user) {
        return donations.listRequested(user);
    }

    @PostMapping("/{id}/request")
    @PreAuthorize("hasRole('INSTITUTION')")
    public DonationResponse request(@AuthenticationPrincipal AuthUser user, @PathVariable Long id) {
        return donations.request(user, id);
    }

    @PostMapping("/{id}/confirm-delivery")
    @PreAuthorize("hasRole('INSTITUTION')")
    public DonationResponse confirmDelivery(@AuthenticationPrincipal AuthUser user, @PathVariable Long id) {
        return donations.confirmDelivery(user, id);
    }

    // ----- qualquer perfil autenticado -----

    @GetMapping("/{id}")
    public DonationResponse get(@AuthenticationPrincipal AuthUser user, @PathVariable Long id) {
        return donations.get(user, id);
    }

    // ----- chat (histórico e envio; o tempo real vem pelo WebSocket) -----

    @GetMapping("/{id}/messages")
    public List<MessageResponse> messages(@AuthenticationPrincipal AuthUser user, @PathVariable Long id) {
        return chat.history(user, id);
    }

    @PostMapping("/{id}/messages")
    @ResponseStatus(HttpStatus.CREATED)
    public MessageResponse sendMessage(@AuthenticationPrincipal AuthUser user, @PathVariable Long id,
                                       @Valid @RequestBody MessageRequest request) {
        return chat.send(user, id, request.content());
    }
}
